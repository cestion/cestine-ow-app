#!/usr/bin/env python3
"""Add a freshly uploaded build to its TestFlight tester groups.

altool --upload-app only delivers the IPA; the build then sits in TestFlight
undistributed until someone adds it to a group by hand. This closes that gap.

App Store Connect's own "Enable automatic distribution" checkbox does the same
thing for free, but only for internal groups and only if it was ticked when
the group was created -- changing it means recreating the group, which shows
existing testers "Tester Removed". Doing it from CI works for internal and
external groups alike and leaves the groups untouched.

With --keep N it also expires older builds, leaving the newest N usable. Apple
never deletes an uploaded build -- expiring is the only way to get one out of
testers' hands, and the row stays in the list either way.

Usage:
  testflight_distribute.py --list
  testflight_distribute.py --build-version 123 --groups "内部测试,QA" --keep 3

Credentials come from the environment (not argv -- argv is visible in `ps`):
  ASC_KEY_CONTENT, ASC_KEY_ID, ASC_ISSUER_ID, ASC_BUNDLE_ID
"""
import argparse
import os
import sys
import time

from asc_api import AscClient, AscError

# The build resource shows up in the API a minute or two after altool returns,
# but stays in PROCESSING for another 5-15 while Apple scans it. External
# groups reject a build that is not yet VALID, so we have to wait it out.
# The wait is bounded and tunable because it burns wall-clock inside a job that
# is already the slowest thing in the repo (150-minute timeout on a macOS runner).
POLL_INTERVAL = 30
DEFAULT_TIMEOUT = 900


class BuildRejected(Exception):
    """App Store Connect finished processing and refused the binary."""


def log(msg):
    print(msg, file=sys.stderr, flush=True)


def gh_notice(level, msg):
    """Emit a GitHub Actions annotation, collapsed to one line."""
    print(f"::{level}::" + msg.replace("\n", " "), flush=True)


def client_from_env():
    missing = [
        k
        for k in ("ASC_KEY_CONTENT", "ASC_KEY_ID", "ASC_ISSUER_ID", "ASC_BUNDLE_ID")
        if not os.environ.get(k)
    ]
    if missing:
        raise SystemExit(f"missing env: {', '.join(missing)}")
    return (
        AscClient(
            os.environ["ASC_KEY_CONTENT"],
            os.environ["ASC_KEY_ID"],
            os.environ["ASC_ISSUER_ID"],
        ),
        os.environ["ASC_BUNDLE_ID"],
    )


def fetch_groups(api, app_id):
    data = api.request("GET", f"/v1/betaGroups?filter[app]={app_id}&limit=200")
    return (data or {}).get("data") or []


def describe(group):
    attrs = group.get("attributes", {})
    kind = "内部" if attrs.get("isInternalGroup") else "外部"
    auto = "，已开自动分发" if attrs.get("hasAccessToAllBuilds") else ""
    return f"{attrs.get('name')!r} ({kind}组{auto}, id={group['id']})"


def cmd_list(api, app_id):
    groups = fetch_groups(api, app_id)
    if not groups:
        gh_notice("warning", "这个 app 在 App Store Connect 上还没有任何 TestFlight 群组")
        return 0
    log("App Store Connect 上的 TestFlight 群组:")
    for g in groups:
        log(f"  - {describe(g)}")
    gh_notice(
        "notice",
        "可用群组: "
        + ", ".join(repr(g["attributes"]["name"]) for g in groups)
        + " —— 把要自动分发的名字填进仓库 Variable TESTFLIGHT_GROUPS（逗号分隔）",
    )
    return 0


def wait_for_build(api, app_id, version, timeout):
    """Poll until the build exists and finished processing. Returns its id."""
    deadline = time.time() + timeout
    seen_state = None
    while True:
        data = api.request(
            "GET",
            f"/v1/builds?filter[app]={app_id}&filter[version]={version}&limit=1",
        )
        entries = (data or {}).get("data") or []
        if entries:
            build = entries[0]
            state = build.get("attributes", {}).get("processingState")
            if state != seen_state:
                log(f"构建 {version}: {state}")
                seen_state = state
            if state == "VALID":
                return build["id"]
            if state in ("FAILED", "INVALID"):
                # Apple rejected the binary itself. Distribution is moot and the
                # reason is on the ASC build page, not in this API response.
                # altool exits 0 for this, so the red X here is the only signal.
                raise BuildRejected(
                    f"构建 {version} 处理失败 (processingState={state})，"
                    "去 App Store Connect 的构建页看具体原因"
                )
        elif seen_state is None:
            log(f"构建 {version}: 还没出现在 App Store Connect，等待中")
            seen_state = "(absent)"

        if time.time() >= deadline:
            return None
        time.sleep(POLL_INTERVAL)


def expire_old_builds(api, app_id, keep, protect_id):
    """Expire every live build except the newest `keep`. Returns what it did.

    Apple has no un-expire and no delete: PATCH expired=true is one-way, and a
    mistake costs a re-upload under a fresh build number. So this re-reads each
    build immediately before touching it and skips anything it cannot confirm.
    """
    # keep<=0 means "disabled", not "expire everything". The caller already
    # guards this; duplicating it here so no future caller can turn the default
    # value of an int into a wipe of every build in TestFlight.
    if keep <= 0:
        return [], []

    data = api.request("GET", f"/v1/builds?filter[app]={app_id}&limit=200")

    live = []
    for b in (data or {}).get("data") or []:
        attrs = b.get("attributes", {})
        if attrs.get("expired"):
            continue
        v = attrs.get("version")
        # Sorting happens here, not via sort=-version: ASC returns version as a
        # string, so its sort puts "99" after "123". A build whose version is
        # not a plain integer can't be ordered against the rest -- leave it be
        # rather than guess where it belongs.
        if isinstance(v, str) and v.strip().isdigit():
            live.append((int(v), b["id"]))
    live.sort(reverse=True)

    expired, skipped = [], []
    for version, bid in live[keep:]:
        if bid == protect_id:
            continue  # never the build this run just uploaded
        try:
            cur = (api.request("GET", f"/v1/builds/{bid}") or {}).get("data") or {}
            attrs = cur.get("attributes", {})
            if attrs.get("expired"):
                continue
            if attrs.get("version") != str(version):
                # The id no longer points at the build we decided to expire.
                skipped.append(f"{version}(版本号对不上)")
                continue
            rel = api.request("GET", f"/v1/builds/{bid}/relationships/appStoreVersion")
            if (rel or {}).get("data"):
                # Attached to an App Store version -- in review or already
                # released. Expiring that is a different, much worse mistake.
                skipped.append(f"{version}(已关联 App Store 版本)")
                continue
            api.request(
                "PATCH",
                f"/v1/builds/{bid}",
                {"data": {"type": "builds", "id": bid, "attributes": {"expired": True}}},
            )
            expired.append(version)
        except AscError as exc:
            skipped.append(f"{version}({exc.detail})")
    return expired, skipped


def cmd_distribute(api, app_id, version, wanted, timeout, keep=0):
    groups = fetch_groups(api, app_id)
    by_name = {g["attributes"]["name"]: g for g in groups}

    unknown = [n for n in wanted if n not in by_name]
    if unknown:
        # A typo here means every future build silently goes undistributed --
        # exactly the manual step this script exists to remove. Fail loudly;
        # the IPA is already uploaded and safe either way.
        gh_notice(
            "error",
            f"TESTFLIGHT_GROUPS 里这些群组在 App Store Connect 上不存在: "
            f"{', '.join(map(repr, unknown))}。可用的是: "
            f"{', '.join(map(repr, by_name)) or '(一个都没有)'}。"
            "IPA 已上传成功，只是没能加进群组。",
        )
        return 1

    targets = [by_name[n] for n in wanted]
    log("目标群组:")
    for g in targets:
        log(f"  - {describe(g)}")

    build_id = wait_for_build(api, app_id, version, timeout)
    if build_id is None:
        gh_notice(
            "warning",
            f"等了 {timeout}s，构建 {version} 还没处理完，跳过自动分发。"
            "IPA 已上传成功，去 App Store Connect 手动加一下群组，"
            "或调大仓库 Variable TESTFLIGHT_WAIT_SECONDS 后重跑。",
        )
        return 0

    # Skip groups the build is already in. Re-POSTing an existing linkage is a
    # 409, which would otherwise turn a harmless re-run into a red build.
    data = api.request("GET", f"/v1/builds/{build_id}/relationships/betaGroups")
    already = {e["id"] for e in (data or {}).get("data") or []}

    added, skipped, failed = [], [], []
    for g in targets:
        name = g["attributes"]["name"]
        if g["id"] in already:
            skipped.append(name)
            continue
        try:
            api.request(
                "POST",
                f"/v1/betaGroups/{g['id']}/relationships/builds",
                {"data": [{"type": "builds", "id": build_id}]},
            )
            added.append(name)
        except AscError as exc:
            # One bad group should not stop the others -- partial distribution
            # beats none, and the summary below says exactly which failed.
            log(f"加入 {name!r} 失败: {exc}")
            failed.append(f"{name} ({exc.detail})")

    parts = []
    if added:
        parts.append("已加入 " + ", ".join(map(repr, added)))
    if skipped:
        parts.append("本来就在 " + ", ".join(map(repr, skipped)))
    if failed:
        parts.append("失败 " + "; ".join(failed))
    summary = f"构建 {version}: " + ("，".join(parts) or "无事可做")

    if failed:
        gh_notice("error", summary)
        return 1
    if any(not by_name[n]["attributes"].get("isInternalGroup") for n in added):
        summary += "。外部组的构建会自动送 Beta 审核，通过后测试员才收到"
    gh_notice("notice", summary)

    # Only after the new build is distributed: if we never got that far, the
    # old builds are still the ones testers need.
    if keep > 0:
        gone, kept_back = expire_old_builds(api, app_id, keep, build_id)
        if gone:
            gh_notice(
                "notice",
                f"已过期旧构建 {', '.join(map(str, gone))}(保留最新 {keep} 个)。"
                "Apple 不支持删除,过期后测试员装不了,记录仍留在构建列表里",
            )
        if kept_back:
            gh_notice("warning", "这些旧构建没过期: " + "; ".join(kept_back))
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--list", action="store_true", help="列出现有群组后退出")
    ap.add_argument("--build-version", help="要分发的构建号")
    ap.add_argument("--groups", default="", help="群组名，逗号分隔")
    ap.add_argument("--timeout", type=int, default=DEFAULT_TIMEOUT)
    # Defaults to off: expiring is irreversible, so it has to be asked for.
    ap.add_argument(
        "--keep",
        type=int,
        default=0,
        help="分发成功后把更旧的构建标为过期,只保留最新 N 个(0=不动)",
    )
    args = ap.parse_args()

    api, bundle_id = client_from_env()
    try:
        app_id = api.app_id(bundle_id)
        if args.list:
            return cmd_list(api, app_id)
        wanted = [n.strip() for n in args.groups.split(",") if n.strip()]
        if not wanted:
            # Nothing configured yet: show what is available so the first run
            # tells the user exactly what to put in the Variable.
            log("未配置 TESTFLIGHT_GROUPS，改为列出可用群组。")
            return cmd_list(api, app_id)
        if not args.build_version:
            raise SystemExit("--build-version is required when --groups is set")
        return cmd_distribute(
            api, app_id, args.build_version, wanted, args.timeout, args.keep
        )
    except BuildRejected as exc:
        gh_notice("error", str(exc))
        return 1
    except AscError as exc:
        gh_notice("error", f"App Store Connect API 调用失败 —— {exc}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
