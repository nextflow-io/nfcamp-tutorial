# Tutorial 

## Step 1 - Use of `path` and `tuple` input/output qualifier 

    nextflow run main1.nf 

## Step 2 - Show use of yaml file 

    nextflow run main2.nf -params-file reads.yml

## Step 3 - Show DLS-2 process and workflow

    nextflow run main3.nf

## Step 4 - Multiple use of the same channel

    nextflow run main4.nf

## Step 5 - Creation of a module files: 

   save the process to the file `rnaseq-processes.nf` 

## Step 6 - Inclusion of module file 

    nextflow run main6.nf

## Step 7 - Selection process inclusion 

    include index from './rnaseq-processes' params(params)
    include quant from './rnaseq-processes' params(params)
    include fastqc from './rnaseq-processes' params(params)
    include multiqc from './rnaseq-processes' params(params)

## Step 8 - Create a sub-workflow module file named: `rnaseq-analysis.nf` 

    workflow rnaseq_analysis {
        get: 
            transcriptome
            read_pairs_ch

        main:
            index( transcriptome )
            
            quant( index.out, read_pairs_ch )
            
            fastqc( read_pairs_ch )
            
            multiqc( 
                    quant.out.mix(fastqc.out).collect(),  
                    params.multiqc )

    }

 
## Step 9 - Create two sub-workflows in the main script and use `-entry` to execute them 

    workflow rnaseqForTranscrip1 {
        rnaseq_analysis ( 
            params.transcriptome, 
            Channel .fromFilePairs( params.reads, checkExists: true )  )
    }

    workflow rnaseqForTranscrip2 {
        rnaseq_analysis ( 
            params.transcriptome, 
            Channel .fromFilePairs( params.reads, checkExists: true )  )
    }



    nextflow run main9.nf -entry rnaseqForTranscrip1
    nextflow run main9.nf -entry rnaseqForTranscrip2

## Step 10 - Use two different genome files 

    params.transcript1 = "$baseDir/data/ggal/transcriptome_1.fa"
    params.transcript2 = "$baseDir/data/ggal/transcriptome_2.fa"


invoke both 

    workflow {
        rnaseqForTranscrip1()
        rnaseqForTranscrip2()
    }

## Step 11 - Use of the fork operator


    workflow {
        reads = Channel .fromFilePairs( 'data/ggal/ggal_*_{1,2}.fq' ) 
        transcripts  = Channel.fromPath('data/ggal/transcriptome_*.fa')
        transcripts
            .combine( reads )
            .fork { tuple -> 
            trascript: tuple[0]
            reads: [ tuple[1], tuple[2] ]
            }
            .set { fork_out }
            
        rnaseq_analysis(fork_out)
    }

## Step 12 - Use of pipes 


    workflow {

        Channel .fromFilePairs( 'data/ggal/ggal_*_{1,2}.fq' ).set {reads} 
        Channel.fromPath('data/ggal/transcriptome_*.fa') \
            | combine( reads ) \
            | fork { tuple -> 
                trascript: tuple[0]
                reads: [ tuple[1], tuple[2] ]
            } \
            | rnaseq_analysis

    }


## Step 13 - Use of forkCriteria 

    workflow {
        separateTranscriptFromReads = forkCriteria({ tuple -> 
            trascript: tuple[0]
            reads: [ tuple[1], tuple[2] ]
            })

        Channel.fromFilePairs( 'data/ggal/ggal_*_{1,2}.fq' ).set {reads} 
        Channel.fromPath('data/ggal/transcriptome_*.fa') \
            | combine( reads ) \
            | fork(separateTranscriptFromReads) \
            | rnaseq_analysis
    }

## Step 14 - Use a custom function 

    def getInputForRnaseq( transcriptsPath, readsPath ) {

        def separateTranscriptFromReads = forkCriteria({ tuple -> 
            trascript: tuple[0]
            reads: [ tuple[1], tuple[2] ]
            })

        def reads = Channel.fromFilePairs(readsPath) 
        Channel.fromPath(transcriptsPath) \
            | combine( reads ) \
            | fork(separateTranscriptFromReads) 

    }

    workflow {
        getInputForRnaseq(params.transcripts, params.reads) | rnaseq_analysis
    }

## Step 15 - Use of workflow publish

    * Remove publishDir from processes 
    * Add emit/out to rnaseq_analysis
    * Add publish to the main workflow 

        workflow {
            main:
            getInputForRnaseq(params.transcripts, params.reads) | rnaseq_analysis
            publish:
            rnaseq_analysis.out.fastqc to: 'results/fastqc_files'
            rnaseq_analysis.out.quant to: 'results/quant_files'
            rnaseq_analysis.out.multiqc to: 'results/multiqc_report'
        }