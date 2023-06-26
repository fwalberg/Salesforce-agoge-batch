global with sharing class OldOrderCleanerBatch implements Database.Batchable<SObject> {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {

        Date baseDate = getBaseDate();
        String query = 'SELECT Id, EffectiveDate FROM Order WHERE EffectiveDate < :baseDate';

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Order> scope) {  
        
        if (!scope.isEmpty()) {
            List<ContentDocument> recordAttachmentList = getRecordAttachment(scope);

            if (!recordAttachmentList.isEmpty())
                delete recordAttachmentList;
            
            delete scope;
        }
    }

    global void finish(Database.BatchableContext tc) {
    }

    private Date getBaseDate() {
        Date baseDate = Date.newInstance(1500, 01, 01);
        try {
            Integer fetchParameter = Integer.valueOf(
            DevParameters__mdt.getInstance('MaxNumberMonthsOrder').Value__c) * (-1);

            baseDate = Date.today().addMonths(fetchParameter);
        } catch(Exception e) {
            System.debug('Error parameter: ' + e.getMessage());    
        }

        return baseDate;
    }

    private List<ContentDocument> getRecordAttachment(List<Order> orderList) {
        
        Set<Id> orderIdSet = new Set<Id>();
        for (Order order : orderList) {
            orderIdSet.add(order.Id);
        }

        List<ContentDocumentLink> documentLinkList = [
            SELECT ContentDocument.Title, ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId IN :orderIdSet
        ];
    
    	Set<Id> documentIdSet = new Set<Id>();
    	for (ContentDocumentLink documentLink : documentLinkList) {
        	documentIdSet.add(documentLink.ContentDocumentId);
    	}
    
    	List<ContentDocument> contentDocumentList = [
            SELECT Id, Title 
            FROM ContentDocument 
            WHERE Id IN :documentIdSet
        ];

        return contentDocumentList;
    }
}
