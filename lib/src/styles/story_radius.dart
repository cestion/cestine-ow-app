import 'package:flutter/material.dart';

class StoryRadius {
  StoryRadius._();

  static const double smValue = 6.0;
  static const double mdValue = 8.0;
  static const double lgValue = 10.0;
  static const double xlValue = 14.0;
  static const double xxlValue = 18.0;
  static const double xxxlValue = 22.0;
  static const double pillValue = 999.0;

  static const Radius sm = Radius.circular(smValue);
  static const Radius md = Radius.circular(mdValue);
  static const Radius lg = Radius.circular(lgValue);
  static const Radius xl = Radius.circular(xlValue);
  static const Radius xxl = Radius.circular(xxlValue);
  static const Radius pill = Radius.circular(pillValue);

  static const BorderRadius brSm = BorderRadius.all(sm);
  static const BorderRadius brMd = BorderRadius.all(md);
  static const BorderRadius brLg = BorderRadius.all(lg);
  static const BorderRadius brXl = BorderRadius.all(xl);
  static const BorderRadius brXxl = BorderRadius.all(xxl);
  static const BorderRadius brPill = BorderRadius.all(pill);

  static BorderRadius card = brLg;
  static BorderRadius sheet = const BorderRadius.vertical(
    top: Radius.circular(20),
  );
}
