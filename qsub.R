
#load("~/sampleinfo.rda")
filenames <- readLines("/data2/exome_heshunwen/filenames")
len <- nchar(filenames)

files <- sapply(strsplit(substr(filenames,1,len-6),"_"),function(x) x)
files <- cbind(apply(files[1:5,],2,paste,collapse="_"),files[6,])
ends <- table(files[,1])
samplenames <- names(ends)
s.end <- samplenames[which(ends==1)]
p.end <- samplenames[which(ends==2)]
ref <- "/data/user/hailiangliu/yjliu/ref37.2/human.fa"
picard.dir <- "/data/user/hailiangliu/soft/picard-tools-1.62/"
gatk.dir <- "/data/soft/GenomeAnalysisTK-1.6-11-g3b2fab9/"
known.vcf <- "/data2/ig_exon/Mills_and_1000G_gold_standard.indels.b37.sites.vcf"
for (i in 1:length(s.end)){
  fq <- grep(s.end[i],filenames,value=TRUE)
  system(paste('mkdir',s.end[i],sep=" "))
  setwd(paste('./',s.end[i],'/',sep=""))
  sh <- c(paste('bwa aln -I -t 2 ',ref,' /data2/exome_heshunwen/exome/',fq,' -f out.sai',sep=""),
          'mkfifo out.sam',
          paste('bwa samse -f out.sam -r "@RG\tID:s',i,'\tSM:',s.end[i],'\tPL:Illumina\tLB:',strsplit(s.end[i],"_")[[1]][5],'" ',ref,' out.sai -f',fq,' &',sep=""),
          paste('java -Xmx4g -jar ',picard.dir,'SortSam.jar SO=coordinate VALIDATION_STRINGENCY=LENIENT CREATE_INDEX=true I=out.sam O=out.bam',sep=""),
          'mkfifo out.realign.list',
          paste('java -Xmx4g -jar ',gatk.dir,'GenomeAnalysisTK.jar -T RealignerTargetCreator -R ',ref,' -I out.bam -known ',known.vcf,' -o out.realign.list &',sep=""),
          paste('java -Xmx4g -jar ',gatk.dir,'GenomeAnalysisTK.jar -R ',ref,' -T IndelRealigner -I out.bam -targetIntervals out.realign.list -o out.realign.bam -known ',known.vcf,' -LOD 0.4 &',sep=""),
          paste('java -Xmx6g -Djava.io.tmpdir=./temp -jar ',picard.dir,'MarkDuplicates.jar I=out.realign.bam O=out.realign.markdup.bam METRICS_FILE=./metrics ASSUME_SORTED=false CREATE_INDEX=true VALIDATION_STRINGENCY=LENIENT',sep=""),
          'mkfifo out.base.recal.csv',
          paste('java -Xmx6g -Djava.io.tmpdir=./temp -jar ',gatk.dir,'GenomeAnalysisTK.jar  -l INFO -R ',ref,' -I out.realign.markdup.bam -knownSites ',known.vcf,' -T CountCovariates -cov ReadGroupCovariate -cov ReadGroupCovariate -cov QualityScoreCovariate -cov CycleCovariate -cov DinucCovariate -recalFile out.base.recal.csv -nt 2 &',sep=""),
          paste('java -Xmx4g -Djava.io.tmpdir=./temp -jar ',gatk.dir,'GenomeAnalysisTK.jar -l INFO -R ',ref,' -I out.realign.markdup.bam -T TableRecalibration -o out.realign.markdup.recal.bam -recalFile out.base.recal.csv',sep=""),
          paste('java -Xmx4g -Djava.io.tmpdir=./temp -jar ',picard.dir,'FixMateInformation.jar I=out.realign.markdup.recal.bam O=out.realign.markdup.recal.fix.bam SO=coordinate VALIDATION_STRINGENCY=LENIENT CREATE_INDEX=true',sep="")
          )
  write.table(sh,file="aln.sh", row.names=F, quote=F, col.names=F)
  setwd("../")
}
for (i in 1:length(s.end)){
  fq <- grep(p.end[i],filenames,value=TRUE)
  system(paste('mkdir',p.end[i],sep=" "))
  setwd(paste('./',p.end[i],'/',sep=""))
  sh <- c(paste('bwa aln -I -t 2 ',ref,' /data2/exome_heshunwen/exome/',fq[1],' -f out1.sai',sep=""),
          paste('bwa aln -I -t 2 ',ref,' /data2/exome_heshunwen/exome/',fq[2],' -f out2.sai',sep=""),
          'mkfifo out.sam',
          paste('bwa sampe -f out.sam -r "@RG\tID:p',i,'\tSM:',p.end[i],'\tPL:Illumina\tLB:',strsplit(p.end[i],"_")[[1]][5],'" ',ref,' out1.sai out2.sai ',paste(fq,collapse=" "),' &',sep=""),
          paste('java -Xmx4g -jar ',picard.dir,'SortSam.jar SO=coordinate VALIDATION_STRINGENCY=LENIENT CREATE_INDEX=true I=out.sam O=out.bam',sep=""),
          'mkfifo out.realign.list',
          paste('java -Xmx4g -jar ',gatk.dir,'GenomeAnalysisTK.jar -T RealignerTargetCreator -R ',ref,' -I out.bam -known ',known.vcf,' -o out.realign.list &',sep=""),
          paste('java -Xmx4g -jar ',gatk.dir,'GenomeAnalysisTK.jar -R ',ref,' -T IndelRealigner -I out.bam -targetIntervals out.realign.list -o out.realign.bam -known ',known.vcf,' -LOD 0.4 &',sep=""),
          paste('java -Xmx6g -Djava.io.tmpdir=./temp -jar ',picard.dir,'MarkDuplicates.jar I=out.realign.bam O=out.realign.markdup.bam METRICS_FILE=./metrics ASSUME_SORTED=false CREATE_INDEX=true VALIDATION_STRINGENCY=LENIENT',sep=""),
          'mkfifo out.base.recal.csv',
          paste('java -Xmx6g -Djava.io.tmpdir=./temp -jar ',gatk.dir,'GenomeAnalysisTK.jar  -l INFO -R ',ref,' -I out.realign.markdup.bam -knownSites ',known.vcf,' -T CountCovariates -cov ReadGroupCovariate -cov ReadGroupCovariate -cov QualityScoreCovariate -cov CycleCovariate -cov DinucCovariate -recalFile out.base.recal.csv -nt 2 &',sep=""),
          paste('java -Xmx4g -Djava.io.tmpdir=./temp -jar ',gatk.dir,'GenomeAnalysisTK.jar -l INFO -R ',ref,' -I out.realign.markdup.bam -T TableRecalibration -o out.realign.markdup.recal.bam -recalFile out.base.recal.csv',sep=""),
          paste('java -Xmx4g -Djava.io.tmpdir=./temp -jar ',picard.dir,'FixMateInformation.jar I=out.realign.markdup.recal.bam O=out.realign.markdup.recal.fix.bam SO=coordinate VALIDATION_STRINGENCY=LENIENT CREATE_INDEX=true',sep="")
          )
  write.table(sh,file="aln.sh", row.names=F, col.names=F, quote=F)
  #system('qsub aln.sh')
  setwd("../")
}

#system("qsub -l nodes=node1:ppn=1 .sh")
for (i in 1:length(s.end)){
  setwd(paste('./',s.end[i],'/',sep=""))
  system('qsub -l nodes=node5:ppn=2 aln.sh')
  setwd("../")
}
for (i in 1:length(p.end)){
  setwd(paste('./',p.end[i],'/',sep=""))
  system(paste('qsub -l nodes=node',i%%3+6,':ppn=2 aln.sh', sep=""))
  setwd("../")
}

