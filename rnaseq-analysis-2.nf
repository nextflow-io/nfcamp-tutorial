nextflow.preview.dsl=2

include index from './rnaseq-processes-2' params(params)
include quant from './rnaseq-processes-2' params(params)
include fastqc from './rnaseq-processes-2' params(params)
include multiqc from './rnaseq-processes-2' params(params)


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

    emit:
        quant = quant.out
        fastqc = fastqc.out   
        multiqc = multiqc.out
}

