enum ConsoleStyles {
  normal,
  bold,
  opacity,
  italic,
  underline,
  clineote,
  clineoteFast,
  none,
  normal2,
  lineThrought,
}

enum ConsoleColors {
  black,
  red,
  green,
  yellow,
  navy,
  violet,
  teal,
  white,
}

class Console {
  static log(
    dynamic text, {
    ConsoleColors color = ConsoleColors.white,
    ConsoleStyles consoleStyle = ConsoleStyles.bold,
  }) {
    print('\x1B[${color.index + 30}m $text\x1B[${consoleStyle.index}m');
  }
}
