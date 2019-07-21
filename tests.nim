import intsets


var s1 = initIntSet()
s1.incl(1)
s1.incl(2)


var s2 = initIntSet()
s2.incl(1)
s2.incl(3)


var s3 = initIntSet()
s3.incl(1)
s3.incl(4)


echo s1.intersection(s2).intersection(s3)