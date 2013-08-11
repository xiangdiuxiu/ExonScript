pairlist=/data/user/dingweijie/test.data/pair-list1.txt  #这个文件记录了所有的pair-end的文件名
cat /data/user/dingweijie/data2/pair-end-full.txt|while read name
do
   FILE=/data2/exome_heshunwen/exome/$name
   ROW=/data/user/dingweijie/test.data/$name.row
   less $FILE | head -n 10000 | awk 'NR%4==0 {print $0}' > $ROW  #把fq文件前10000行中所有表示质量的行，即行数为4的倍数的行
   a=`cat $ROW | grep '[A-Za-z0-9]' | wc -l`  #判断这个文件是不是空的文件（确实有一个文件在复制的过程中出了问题，是空文件）
   if [ $a -eq 0 ];then
      echo $FILE'	'0 >> $pairlist
   else
      b=`cat $ROW | grep '[KLMNOPQRSTUVWXYZ\^_abcdefgh]' | wc -l` #判断format是否属于X/I/J
      if [ $b -gt 0 ];then
         echo $FILE'	'1 >> $pairlist #如果是，将文件名写入pairlist 文件， 然后在行尾用1标记
      else
         echo $FILE'	'2 >> $pairlist
      fi
   fi
done
