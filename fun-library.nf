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