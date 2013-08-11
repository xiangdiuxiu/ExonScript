singlelist=/data/user/dingweijie/test.data/single-list.txt
cat /data/user/dingweijie/data2/single-end.txt|while read name
do
   FILE=/data2/exome_heshunwen/exome/$name
   ROW=/data/user/dingweijie/test.data/$name.row
   less $FILE | head -n 100 | awk 'NR%4==0 {print $0}' > $ROW
   a=`cat $ROW | grep '[A-Za-z0-9]' | wc -l`
   if [ $a -eq 0 ];then
      echo $FILE'	'0 >> $singlelist
   else
      b=`cat $ROW | grep '[KLMNOPQRSTUVWXYZ\^_abcdefgh]' | wc -l`
      if [ $b -gt 0 ];then
         echo $FILE'	'1 >> $singlelist
      else
         echo $FILE'	'2 >> $singlelist
      fi
   fi
done
