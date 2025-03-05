include { ART_ILLUMINA as HUMAN_READS } from '../../modules/nf-core/art/illumina/main'
include { ART_ILLUMINA as BUG_READS   } from '../../modules/nf-core/art/illumina/main'

workflow SIMULATE {

    take:
    ch_human_fasta
    ch_bug_fasta
    ch_seed

    main:

    ch_versions = Channel.empty()
    
    def human_reads = params.reads * params.fraction_human
    def bug_reads = params.reads - human_reads
    
    HUMAN_READS ( ch_human_fasta,
                  params.sequencing_system,
                  human_reads,
                  params.read_length,
                  ch_seed
                 )
                 
    ch_versions = ch_versions.mix(HUMAN_READS.out.versions.first())
    
    BUG_READS ( ch_bug_fasta,
                params.sequencing_system,
                bug_reads,
                params.read_length,
                ch_seed
                )
                
    ch_versions = ch_versions.mix(BUG_READS.out.versions.first())
    
    emit:
    human_reads      = HUMAN_READS.out.fastq           // channel: [ val(meta), [ fq.gz ] ]
    bug_reads        = BUG_READS.out.fastq             // channel: [ val(meta), [ fq.gz ] ]

    versions         = ch_versions                     // channel: [ versions.yml ]
}

