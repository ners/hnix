let {

  x = "a";
  y = "b";

  f = {x ? y, y ? x}: x + y;

  body = f {};

}
