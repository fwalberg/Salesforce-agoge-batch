public with sharing class SchedulerOldOrderCleanerBatch implements Schedulable {

    public void execute(SchedulableContext context) {
        Integer batchSize = getBathSize();

        OldOrderCleanerBatch batch = new OldOrderCleanerBatch();
        Database.executebatch(batch, batchSize);
    }

    private Integer getBathSize() {
        Integer batchSize = 200;
        try {
            Integer fetchParameter = Integer.valueOf(
            DevParameters__mdt.getInstance('BatchSize').Value__c);

            if(fetchParameter <= 2000)
                batchSize = fetchParameter;

        } catch (Exception e) {
            System.debug('Error parameter: ' + e.getMessage());
        }

        return batchSize;
    }
}