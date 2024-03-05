extension SymbolName on Symbol {
  String get name {
    final symbol = toString();
    return symbol.substring(8, symbol.length - 2);
  }
}
