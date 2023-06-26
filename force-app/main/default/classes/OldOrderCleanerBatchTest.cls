@isTest
public with sharing class OldOrderCleanerBatchTest {
    @TestSetup
    static void makeData(){
        TestFactorySObject sobjectFactory = TestFactorySObject.getInstance();

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        Account account = (Account)sobjectFactory.createSObject(new Account());
        insert account;

        Order olderOrder1 = (Order)sobjectFactory.createSObject(new Order(
            AccountId = account.Id,
            Pricebook2Id = standardPricebook.Id
        ));

        Order olderOrder2 = (Order)sobjectFactory.createSObject(new Order(
            AccountId = account.Id,
            Pricebook2Id = standardPricebook.Id
        ));

        Order newOrder1 = (Order)sobjectFactory.createSObject(new Order(
            AccountId = account.Id,
            Pricebook2Id = standardPricebook.Id
        ));

        Order newOrder2 = (Order)sobjectFactory.createSObject(new Order(
            AccountId = account.Id,
            Pricebook2Id = standardPricebook.Id
        ));

        List<Order> orderList = new List<Order> {
            newOrder1,
            newOrder2,
            olderOrder1,
            olderOrder2
        };
        insert orderList;

        //Set createdDate
        Test.setCreatedDate(olderOrder1.Id, Date.today().addMonths(-7)); // Out of date;
        Test.setCreatedDate(olderOrder2.Id, Date.today().addMonths(-6)); // on the deadline;
        Test.setCreatedDate(newOrder1.Id, Date.today().addMonths(-5)); // on expiration date

        // Create files
        List<ContentVersion> contentVersionList = new List<ContentVersion>{
            (ContentVersion)sobjectFactory.createSObject(new ContentVersion()),
            (ContentVersion)sobjectFactory.createSObject(new ContentVersion()),
            (ContentVersion)sobjectFactory.createSObject(new ContentVersion())
        };
        insert contentVersionList;

        List<ContentVersion> documentList = [
            SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Title LIKE '%Test%'
        ];

        // Create ContentDocumentLink
        List<ContentDocumentLink> documentLinkList = new List<ContentDocumentLink>();
        for (ContentVersion document : documentList) {
            ContentDocumentLink documentLink = (ContentDocumentLink)sobjectFactory.createSObject(new ContentDocumentLink(
                LinkedEntityId = olderOrder1.Id,
                ContentDocumentId = document.ContentDocumentId    
            )); 
            
            documentLinkList.add(documentLink);
        }
        insert documentLinkList;
    } 

    @isTest
    // Verifica se os pedidos com seis meses ou mais foram deletados.
    static void checkOrderDeleted(){
        Test.startTest();       

        OldOrderCleanerBatch batch = new OldOrderCleanerBatch();
        Database.executebatch(batch, 10);

        Test.stopTest();

        List<Order> orderListData = [
            SELECT Id, CreatedDate FROM Order
        ];

        System.assertEquals(orderListData.size() == 2, true, 'The list needs to have only two objects.');
    }

    @isTest
    // Verifica se os anexos vinculados aos pedidos excluídos foram deletados.
    static void checkAttachmentDeleted(){
        Test.startTest();       

        OldOrderCleanerBatch batch = new OldOrderCleanerBatch();
        Database.executebatch(batch, 10);

        Test.stopTest();

        List<ContentDocument> documentList = [
            SELECT Id, Title
            FROM ContentDocument
        ];

        System.assertEquals(documentList.isEmpty(), true, 'The list must be empty.');
    }
}