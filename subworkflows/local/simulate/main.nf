include { ARTILLUMINA as HUMAN_READS } from '../../../modules/nf-core/art/illumina/main'
include { ARTILLUMINA as BUG_READS   } from '../../../modules/nf-core/art/illumina/main'
include { COMBINEREADS               } from '../../../modules/local/combinereads/main'

workflow SIMULATE {

    take:
    ch_human_fasta
    ch_bug_fasta
    ch_seed

    main:

    ch_versions = Channel.empty()
    
    def human_reads = params.reads * params.fraction_human
    def bug_reads = params.reads - human_reads
    println(human_reads.toInteger())
    println(bug_reads.toInteger())
    
    HUMAN_READS ( ch_human_fasta,
                  params.sequencing_system,
                  human_reads.toInteger(),
                  params.read_length,
                  params.insert_length,
                  params.std_dev,
                  ch_seed
                 )
                 
    ch_versions = ch_versions.mix(HUMAN_READS.out.versions.first())
    
    BUG_READS ( ch_bug_fasta,
                params.sequencing_system,
                bug_reads.toInteger(),
                params.read_length,
                params.insert_length,
                params.std_dev,
                ch_seed
                )
                
    ch_versions = ch_versions.mix(BUG_READS.out.versions.first())
    
    // combine the human and bug simulated reads into a single fastq file for each sample
    ch_combined_reads = BUG_READS.out.fastq.combine(HUMAN_READS.out.fastq, by:0)
    ch_combined_reads.view()
    
    COMBINEREADS ( ch_combined_reads )
    
    ch_versions = ch_versions.mix(COMBINEREADS.out.versions.first())
    
    emit:
    //human_reads      = HUMAN_READS.out.fastq           // channel: [ val(meta), [ fq.gz ] ]
    //bug_reads        = BUG_READS.out.fastq             // channel: [ val(meta), [ fq.gz ] ]

    versions         = ch_versions                     // channel: [ versions.yml ]
}

