import 'package:flutter/material.dart';

//colorescon el frontend web
class AppColors {
  AppColors._(); // Constructor privado para evitar instanciación

  // Colores base
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Escala de grises
  static const Color gray100 = Color(0xFFF8F9FA);
  static const Color gray200 = Color(0xFFE9ECEF);
  static const Color gray300 = Color(0xFFF1F2F1);
  static const Color gray400 = Color(0xFFCED4DA);
  static const Color gray500 = Color(0xFFA09E9E);
  static const Color gray600 = Color(0xFF6C757D);
  static const Color gray700 = Color(0xFF495057);
  static const Color gray800 = Color(0xFF343A40);
  static const Color gray900 = Color(0xFF212529);

  // Colores azules
  static const Color blue300 = Color(0xFF88DFFB);
  static const Color blue = Color(0xFF32BDEA);
  static const Color blue800 = Color(0xFF06A3D6);

  // Colores rojos
  static const Color red300 = Color(0xFFF1C8DB);
  static const Color red = Color(0xFFE08DB4);
  static const Color red800 = Color(0xFFD85E97);

  // Colores amarillos
  static const Color yellow300 = Color(0xFFFFAA8A);
  static const Color yellow = Color(0xFFFF9770);
  static const Color yellow800 = Color(0xFFFF6A32);

  // Colores verdes
  static const Color green300 = Color(0xFFA0D9B4);
  static const Color green = Color(0xFF78C091);
  static const Color green800 = Color(0xFF478F60);

  // Colores cyan
  static const Color cyan300 = Color(0xFF9AE8FF);
  static const Color cyan = Color(0xFF7EE2FF);
  static const Color cyan800 = Color(0xFF58D9FF);

  // Colores naranjas
  static const Color orange300 = Color(0xFFF8BEA3);
  static const Color orange = Color(0xFFFF7E41);
  static const Color orange800 = Color(0xFFFE5708);

  // Colores morados
  static const Color purple300 = Color(0xFFCBC0FF);
  static const Color purple = Color(0xFF4731B6);
  static const Color purple800 = Color(0xFF9E8AFF);

  // Colores azul cielo
  static const Color skyblue300 = Color(0xFFAAD7FF);
  static const Color skyblue = Color(0xFF158DF7);
  static const Color skyblue800 = Color(0xFF117EDE);

  // Colores rosa oscuro
  static const Color pinkdark300 = Color(0xFFFFF1F1);
  static const Color pinkdark = Color(0xFFE91E63);
  static const Color pinkdark800 = Color(0xFF2B2626);

  // Otros colores
  static const Color light = Color(0xFFC7CBD3);
  static const Color lightGray = Color(0xFFF4F5FA);
  static const Color indigo = Color(0xFF6610F2);
  static const Color teal = Color(0xFF20C997);

  // Colores modo oscuro
  static const Color darkBodyBg = Color(0xFF0D0D0D);
  static const Color darkBodyText = Color(0xFF676E8A);
  static const Color darkTitleText = Color(0xFFAEA8F5);
  static const Color darkBorderColor = Color(0xFF212532);
  static const Color darkCardBg = Color(0xFF0D0D0D);
  static const Color darkGray = Color(0xFF151515);

  // Colores modo claro
  static const Color bodyBg = Color(0xFFFFFFFF);
  static const Color bodyText = Color(0xFF676E8A);
  static const Color titleText = Color(0xFF110A57);
  static const Color borderColor = Color(0xFFDCDFE8);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color bodyTextDark = Color(0xFF595A5D);

  // Colores del sidebar y UI
  static const Color sidebarPrimaryLight = Color(0xFFE4ECFD);
  static const Color sidebarIconLight = Color(0xFF5D8EF7);
  static const Color grayLight = Color(0xFFEFF1FE);
  static const Color grayDark1 = Color(0xFF16171D);
  static const Color grayDarkHover = Color(0xFF191A20);
  static const Color introLightBg = Color(0xFFFAFBFE);
  static const Color introDarkBg = Color(0xFF2B343B);
  static const Color sidebarPurpleShade = Color(0xFF876CFE);
  static const Color collapseLightShade = Color(0xFFFFEBDF);
  static const Color collapseDarkShade = Color(0xFFFE721C);
  static const Color sidebarBlackShade = Color(0xFF01041B);
  static const Color nyonGreenShade = Color(0xFF37E6B0);
  static const Color sidebarNaviShade = Color(0xFF040849);

  // Colores de tema (primary, secondary, etc.)
  static const Color primaryLight = blue300;
  static const Color primary = blue;
  static const Color primaryDark = blue800;

  static const Color secondaryLight = orange300;
  static const Color secondary = orange;
  static const Color secondaryDark = orange800;

  static const Color successLight = green300;
  static const Color success = green;
  static const Color successDark = green800;

  static const Color infoLight = cyan300;
  static const Color info = cyan;
  static const Color infoDark = cyan800;

  static const Color warningLight = yellow300;
  static const Color warning = yellow;
  static const Color warningDark = yellow800;

  static const Color dangerLight = red300;
  static const Color danger = red;
  static const Color dangerDark = red800;

  // Colores oscuros con transparencia (para fondos)
  static const Color darkPrimary = Color(0x1A4788FF); // rgba(71, 136, 255, 0.1)
  static const Color darkSecondary = Color(0x1A6C757D); // rgba(108, 117, 125, 0.1)
  static const Color darkSuccess = Color(0x1A37E6B2); // rgba(55, 230, 178, 0.1)
  static const Color darkInfo = Color(0x1A876CFE); // rgba(135, 108, 254, 0.1)
  static const Color darkWarning = Color(0x1AFE721C); // rgba(254, 114, 28, 0.1)
  static const Color darkDanger = Color(0x1AFF4B4B); // rgba(255, 75, 75, 0.1)
  static const Color darkLight = Color(0x1AC7CBD3); // rgba(199, 203, 211, 0.1)
  static const Color darkDark = Color(0x1A01041B); // rgba(1, 4, 27, 0.1)
  static const Color darkOrange = Color(0x1AFD7E14); // rgba(253, 126, 20, 0.1)
  static const Color darkPurple = Color(0x1A4731B6); // rgba(71, 49, 182, 0.1)

  // Gradientes
  static const Color startColor = Color(0xFFFFFFFF);
  static const Color endColor = Color(0xFFFFFFFF);
}

