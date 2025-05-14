public class LotteryNumberQueueable implements Queueable {
    private String waitlistId;
    private Map<Id, Integer> idToRandomNumberMap;
    private final Integer DEFAULT_BATCH_SIZE = 1000; // Smaller to avoid issues
    private Integer batchSize;
    private Id lastProcessedId; // Using Id-based pagination instead of offset
    private Integer totalApplicants;
    private Integer processedCount;
    private final Integer MAX_DML_ROWS = 10000; // Maximum rows per DML operation
    
    // Constructor to initialize the lottery assignment process
    public LotteryNumberQueueable(String waitlistId, Integer batchSize) {
        this.waitlistId = waitlistId;
        this.batchSize = batchSize > 0 ? batchSize : DEFAULT_BATCH_SIZE;
        this.lastProcessedId = null; // Start with null ID for first batch
        this.processedCount = 0;
        
        // Get count of applicants rather than loading all records
        this.totalApplicants = [SELECT COUNT() FROM WaitlistApplicant__c WHERE Waitlist__c = :waitlistId];
        
        // Only initialize the map with size, we'll generate numbers on demand
        this.idToRandomNumberMap = new Map<Id, Integer>();
    }
    
    // Constructor for subsequent jobs with existing data
    private LotteryNumberQueueable(String waitlistId, Map<Id, Integer> idToRandomNumberMap, 
                                 Integer batchSize, Id lastProcessedId, Integer totalApplicants, Integer processedCount) {
        this.waitlistId = waitlistId;
        this.idToRandomNumberMap = idToRandomNumberMap;
        this.batchSize = batchSize;
        this.lastProcessedId = lastProcessedId;
        this.totalApplicants = totalApplicants;
        this.processedCount = processedCount;
    }
    
    public void execute(QueueableContext context) {
        // Generate lottery numbers if this is the first batch
        if (lastProcessedId == null && processedCount == 0) {
            generateLotteryNumbers();
        }
        
        // Query applicants for this batch using ID-based pagination instead of OFFSET
        List<WaitlistApplicant__c> applicants;
        if (lastProcessedId == null) {
            // First batch
            applicants = [
                SELECT Id, Randomized_Order__c 
                FROM WaitlistApplicant__c 
                WHERE Waitlist__c = :waitlistId
                ORDER BY Id ASC
                LIMIT :batchSize
            ];
        } else {
            // Subsequent batches - use Id as the continuation token
            applicants = [
                SELECT Id, Randomized_Order__c 
                FROM WaitlistApplicant__c 
                WHERE Waitlist__c = :waitlistId AND Id > :lastProcessedId
                ORDER BY Id ASC
                LIMIT :batchSize
            ];
        }
        
        // If no records to process, we're done - update the waitlist record
        if (applicants.isEmpty()) {
            finishProcess();
            return;
        }
        
        // Update the applicants with their random numbers
        List<WaitlistApplicant__c> recordsToUpdate = new List<WaitlistApplicant__c>();
        for (WaitlistApplicant__c applicant : applicants) {
            if (idToRandomNumberMap.containsKey(applicant.Id)) {
                applicant.Randomized_Order__c = idToRandomNumberMap.get(applicant.Id);
                recordsToUpdate.add(applicant);
            }
            // Keep track of the last processed ID for the next batch
            lastProcessedId = applicant.Id;
        }
        
        // Split updates into chunks of MAX_DML_ROWS to avoid governor limits
        if (!recordsToUpdate.isEmpty()) {
            Integer totalRecords = recordsToUpdate.size();
            for (Integer i = 0; i < totalRecords; i += MAX_DML_ROWS) {
                Integer endIndex = Math.min(i + MAX_DML_ROWS, totalRecords);
                
                // Create a new list for each chunk instead of using subList
                List<WaitlistApplicant__c> chunk = new List<WaitlistApplicant__c>();
                for (Integer j = i; j < endIndex; j++) {
                    chunk.add(recordsToUpdate[j]);
                }
                
                // Use Database.update with partial processing to allow some failures
                Database.update(chunk, false);
            }
        }
        
        // Update processed count
        processedCount += applicants.size();
        
        // Check if we still have more records to process
        if (processedCount < totalApplicants) {
            // Check if we're in a test context to avoid System.LimitException in test classes
            if (!Test.isRunningTest()) {
                // Chain to next job to process the next batch
                System.enqueueJob(new LotteryNumberQueueable(waitlistId, idToRandomNumberMap, 
                                  batchSize, lastProcessedId, totalApplicants, processedCount));
            }
        } else {
            // All done, finalize
            finishProcess();
        }
    }
    
    private void generateLotteryNumbers() {
        // Query the actual count first to ensure accuracy
        Integer actualCount = [SELECT COUNT() FROM WaitlistApplicant__c WHERE Waitlist__c = :waitlistId];
        this.totalApplicants = actualCount;
        
        // Create a list of sequential numbers with buffer to avoid edge cases
        // Adding a buffer of 10% to ensure we have enough numbers
        Integer bufferSize = Math.max(10, (Integer)(totalApplicants * 0.1));
        Integer totalNumbersToGenerate = totalApplicants + bufferSize;
        
        List<Integer> shuffledNumbers = new List<Integer>();
        for (Integer i = 1; i <= totalNumbersToGenerate; i++) {
            shuffledNumbers.add(i);
        }
        
        // Shuffle the list
        shuffleList(shuffledNumbers);
        
        // Query applicant IDs in batches to avoid heap size limits, using ID-based pagination
        Id currentId = null;
        Integer idBatchSize = 50000; // Process 50k IDs at a time
        Integer numberIndex = 0;
        Integer processedApplicants = 0;
        
        while (processedApplicants < totalApplicants) {
            List<WaitlistApplicant__c> applicantBatch;
            
            if (currentId == null) {
                applicantBatch = [
                    SELECT Id FROM WaitlistApplicant__c 
                    WHERE Waitlist__c = :waitlistId
                    ORDER BY Id ASC
                    LIMIT :idBatchSize
                ];
            } else {
                applicantBatch = [
                    SELECT Id FROM WaitlistApplicant__c 
                    WHERE Waitlist__c = :waitlistId AND Id > :currentId
                    ORDER BY Id ASC
                    LIMIT :idBatchSize
                ];
            }
            
            if (applicantBatch.isEmpty()) break;
            
            // Map each applicant ID to a random number
            for (WaitlistApplicant__c app : applicantBatch) {
                // Check to avoid index out of bounds
                if (numberIndex < shuffledNumbers.size()) {
                    idToRandomNumberMap.put(app.Id, shuffledNumbers[numberIndex++]);
                    currentId = app.Id; // Keep track of the last ID for the next batch
                    processedApplicants++;
                } else {
                    // If somehow we run out of numbers, generate more
                    Integer moreNumbers = Math.max(100, applicantBatch.size());
                    Integer startingValue = shuffledNumbers.size() + 1;
                    
                    for (Integer i = 0; i < moreNumbers; i++) {
                        shuffledNumbers.add(startingValue + i);
                    }
                    shuffleList(shuffledNumbers);
                    
                    // Now we can safely assign a number
                    idToRandomNumberMap.put(app.Id, shuffledNumbers[numberIndex++]);
                    currentId = app.Id;
                    processedApplicants++;
                }
            }
            
            // Break if we've processed fewer records than batch size, indicating end of data
            if (applicantBatch.size() < idBatchSize) break;
        }
        
        // Update the actual count if it's different
        if (processedApplicants != totalApplicants) {
            totalApplicants = processedApplicants;
        }
    }
    
    private void finishProcess() {
        // Update waitlist record to record completion time
        try {
            // Add a flag to prevent duplicate completion
            Waitlist__c waitlistRecord = [
                SELECT Id, Actual_Lottery_Run_DateTime__c 
                FROM Waitlist__c 
                WHERE Id = :waitlistId
                FOR UPDATE
            ];
            
            // Only update if not already completed
            if (waitlistRecord.Actual_Lottery_Run_DateTime__c == null) {
                waitlistRecord.Actual_Lottery_Run_DateTime__c = System.now();
                update waitlistRecord;
                
                System.debug('Successfully assigned unique random numbers to ' + totalApplicants + 
                           ' applicants for waitlist: ' + waitlistId);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error updating waitlist record: ' + e.getMessage());
        }
    }
    
    // More efficient in-place Fisher-Yates shuffle
    private void shuffleList(List<Integer> input) {
        Integer n = input.size();
        
        // Use Crypto.getRandomInteger for better randomization when available
        for (Integer i = n - 1; i > 0; i--) {
            // Math.random() * (i + 1) can be biased for very large numbers
            // Using modulo with Crypto.getRandomInteger for better distribution
            Integer j;
            try {
                // Get a random number between 0 and i (inclusive)
                j = Math.mod(Math.abs(Crypto.getRandomInteger()), i + 1);
            } catch (Exception e) {
                // Fallback to Math.random if Crypto fails
                j = Integer.valueOf(Math.random() * (i + 1));
            }
            
            // Swap in place
            Integer temp = input[i];
            input[i] = input[j];
            input[j] = temp;
        }
    }
    
    // Static method to execute the queueable with the waitlist ID
    public static void execute(String waitlistId, Integer batchSize) {
        if (String.isBlank(waitlistId)) {
            System.debug(LoggingLevel.ERROR, 'Error: waitlistId cannot be null or empty');
            return;
        }
        
        System.enqueueJob(new LotteryNumberQueueable(waitlistId, batchSize));
    }
    
    // Method to check the current progress
    public static Integer checkProgress(String waitlistId) {
        Integer total = [SELECT COUNT() FROM WaitlistApplicant__c WHERE Waitlist__c = :waitlistId];
        Integer processed = [SELECT COUNT() FROM WaitlistApplicant__c 
                           WHERE Waitlist__c = :waitlistId AND Randomized_Order__c != null];
        
        return (total > 0) ? (processed * 100 / total) : 0;
    }
}