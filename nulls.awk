BEGIN {
  OFS="\t"
}
{
  for (i=1; i<=NF; i++) {
    if (!$i) $i="\\N"
  }
  print
}
