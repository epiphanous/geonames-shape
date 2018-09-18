BEGIN {
  OFS="\t"
}
{
  if ($2) {
    split($2,a,",")
    for (x in a) {
      split(a[x],b,"-")
      print $1, b[1]
    }
  }
}
