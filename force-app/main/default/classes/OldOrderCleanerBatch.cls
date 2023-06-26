global with sharing class OldOrderCleanerBatch implements Database.Batchable<SObject> {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {

        Integer fetchParameter = Integer.valueOf(
            DevParameters__mdt.getInstance('MaxNumberMonthsOrder').Value__c) * (-1);

        Datetime baseDate = Date.today().addMonths(fetchParameter);

        String query = 'SELECT Id, CreatedDate FROM Order WHERE CreatedDate <= :baseDate';

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Order> scope) {  
        if(!scope.isEmpty()) {
            
            Set<Id> orderIdSet = new Set<Id>();
            for (Order order : scope) {
                orderIdSet.add(order.Id);
            }

            List<ContentDocumentLink> documentLinkList = [
                SELECT ContentDocument.Title, ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId IN :orderIdSet
            ];
        
            if (!documentLinkList.isEmpty()) {

                Set<Id> documentIdSet = new Set<Id>();
                for (ContentDocumentLink documentLink : documentLinkList) {
                    documentIdSet.add(documentLink.ContentDocumentId);
                }
            
                List<ContentDocument> contentDocumentList = [
                    SELECT Id, Title 
                    FROM ContentDocument 
                    WHERE Id IN :documentIdSet
                ];
                
                delete contentDocumentList;
            }

            delete scope;
        }  
    }

    global void finish(Database.BatchableContext tc) {
    }
}
