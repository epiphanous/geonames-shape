BEGIN {
  OFS="\t"
}
{
  code=$3 ? $3 : $1;
  lang=$4
  print code,lang;
}
