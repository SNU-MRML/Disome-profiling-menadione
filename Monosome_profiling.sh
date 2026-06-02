#!/bin/bash

DIR=$1/$2
GROUP=$3

#seqkit grep -r -p '\|(rRNA|Mt_rRNA|tRNA|Mt_tRNA|snoRNA|snRNA)\|' gencode.v44.transcripts.fa > gencode.v44.transcripts_rRNA_tRNA_snoRNA_snRNA.fa
#bowtie2-build -f gencode.v44.transcripts_rRNA_tRNA_snoRNA_snRNA.fa bowtie2_gencode_v44_rRNA_tRNA_snoRNA_snRNA_index

STAR_genome_directory=/data/genome/human/STAR_genome_2.7.10b
ref_gene_annotation_gtf=/data/genome/human/gencode.v44.primary_assembly.annotation.gtf
genome_fasta=/data/genome/human/GRCh38.primary_assembly.genome.fa


export PATH="/root/package/FastQC/:$PATH"
export PATH="/root/package/fastx_toolkit-0.0.14/:$PATH"
export PATH="/root/package/libgtextutils-0.7/:$PATH"
export PATH="/root/package/STAR-2.7.10b/bin/Linux_x86_64_static:$PATH"


if [ ! -d $DIR/logs ]
then
    mkdir $DIR/logs
fi

if [ ! -d $DIR/fastqc ]
then
    mkdir $DIR/fastqc
fi

if [ ! -d $DIR/fastqc/before_trimmed/ ]
then
    mkdir $DIR/fastqc/before_trimmed
fi

if [ ! -d $DIR/fastqc/before_trimmed/$GROUP ]
then
    mkdir $DIR/fastqc/before_trimmed/$GROUP
fi

if [ ! -d $DIR/fastqc/after_trimmed ]
then
    mkdir $DIR/fastqc/after_trimmed
fi

if [ ! -d $DIR/fastqc/after_trimmed/$GROUP ]
then
    mkdir $DIR/fastqc/after_trimmed/$GROUP
fi

if [ ! -d $DIR/trimmed_fastq ]
then
    mkdir $DIR/trimmed_fastq
fi

if [ ! -d $DIR/trimmed_fastq/$GROUP ]
then
    mkdir $DIR/trimmed_fastq/$GROUP
fi

if [ ! -d $DIR/fastqc/after_filtered ]
then
    mkdir $DIR/fastqc/after_filtered
fi

if [ ! -d $DIR/fastqc/after_filtered/$GROUP ]
then
    mkdir $DIR/fastqc/after_filtered/$GROUP
fi

if [ ! -d $DIR/filtered_fastq ]
then
    mkdir $DIR/filtered_fastq
fi

if [ ! -d $DIR/filtered_fastq/$GROUP ]
then
    mkdir $DIR/filtered_fastq/$GROUP
fi

if [ ! -d $DIR/STAR ]
then
    mkdir $DIR/STAR
fi

if [ ! -d $DIR/STAR/$GROUP ]
then
    mkdir $DIR/STAR/$GROUP
fi

if [ ! -d $DIR/Output/ ]
then
        mkdir $DIR/Output
fi

if [ ! -d $DIR/Output/ ]
then
        mkdir $DIR/Output
fi

DATAPATH=$DIR/raws/$GROUP

FASTQ=$(ls $DATAPATH | egrep '*.fastq.gz*')
FASTQ_LIST=(${FASTQ// / })
for idx in ${!FASTQ_LIST[@]};
do
    SAMPLE=${FASTQ_LIST[idx]%%.fastq*}
    SAMPLE_PATH=${FASTQ_LIST[idx]}
    echo ${FASTQ_LIST[idx]}
    echo $SAMPLE
        
    fastqc -o $DIR/fastqc/before_trimmed/$GROUP --noextract -f fastq -t 12 $DATAPATH/$SAMPLE_PATH
    echo "FastQC is done"

    cutadapt -a AGATCGGAAGAGCACACGTCTGAACTCCAGTCAC -m 20 -M 40 -q 20 -o $DIR/trimmed_fastq/$GROUP/$SAMPLE"_trimmed.fastq.gz" \
    $DATAPATH/$SAMPLE_PATH
    echo "Cutadapt is done" 

    echo " "
    fastqc -o $DIR/fastqc/after_trimmed/$GROUP --noextract -f fastq -t 12 $DIR/trimmed_fastq/$GROUP/$SAMPLE"_trimmed.fastq.gz"
    echo "Trimmed_FastQC is done"

    echo " "
    bowtie2 -p 12 -x /data/genome/human/bowtie2_gencode_v44_rRNA_tRNA_snoRNA_snRNA_index/bowtie2_gencode_v44_rRNA_tRNA_snoRNA_snRNA_index \
    -U $DIR/trimmed_fastq/$GROUP/$SAMPLE"_trimmed.fastq.gz" \
    --un-gz $DIR/filtered_fastq/$GROUP/$SAMPLE"_filtered.fastq.gz" -S /dev/null
    echo "Bowtie2 is done"

    echo " "
    fastqc -o $DIR/fastqc/after_filtered/$GROUP --noextract -f fastq -t 12 $DIR/filtered_fastq/$GROUP/$SAMPLE"_filtered.fastq.gz"
    echo "Filtered_FastQC is done"

    if [ ! -d $DIR/STAR/$GROUP/$SAMPLE_NAME ]
    then
        mkdir $DIR/STAR/$GROUP/$SAMPLE_NAME
    fi

    echo " "
    STAR --runMode alignReads --runThreadN 12 --genomeDir $STAR_genome_directory \
    --readFilesIn $DIR/filtered_fastq/$GROUP/$SAMPLE"_filtered.fastq.gz" --readFilesCommand zcat \
    --outFileNamePrefix $DIR/STAR/$GROUP/$SAMPLE_NAME/$SAMPLE_NAME"_" --outSAMtype BAM SortedByCoordinate \
    --quantMode TranscriptomeSAM  --outSAMattributes All --outFilterType BySJout --outFilterMultimapNmax 1 --outFilterMatchNmin 15 \
    --alignEndsType EndToEnd --alignSJoverhangMin 8 --alignSJDBoverhangMin 1 --outFilterMismatchNmax 2 \
    --alignIntronMin 20 --alignIntronMax 1000000 --alignMatesGapMax 1000000 --outFilterIntronStrands RemoveInconsistentStrands
    echo "STAR is done"
        
done