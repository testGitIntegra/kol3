/**
 * Сервис для синхронизации данных между Salesforce и PostgreSQL
 * Поддерживает двустороннюю синхронизацию для Leads, Contacts, Opportunities
 */
public with sharing class SyncService {
    
    public enum SyncDirection {
        TO_POSTGRES,    // Из Salesforce в PostgreSQL
        FROM_POSTGRES,  // Из PostgreSQL в Salesforce
        BIDIRECTIONAL   // Двусторонняя синхронизация
    }
    
    public enum ObjectType {
        LEAD,
        CONTACT,
        OPPORTUNITY
    }
    
    /**
     * Синхронизация из Salesforce в PostgreSQL
     */
    public static SyncResult syncToPostgreSQL(ObjectType objType, List<Id> recordIds) {
        SyncResult result = new SyncResult();
        result.objectType = objType.name();
        result.direction = 'TO_POSTGRES';
        Datetime startTime = Datetime.now();
        
        addLog(result, 'INFO', 'Начало синхронизации в PostgreSQL');
        
        try {
            List<SObject> records = queryRecords(objType, recordIds);
            
            if (records.isEmpty()) {
                result.success = true;
                result.message = 'Нет записей для синхронизации';
                addLog(result, 'INFO', result.message);
                return finalize(result, startTime);
            }
            
            List<Map<String, Object>> payload = preparePayload(records, objType);
            HttpResponse response = callPostgreSQLAPI('sync', payload);
            
            if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                
                result.success = (Boolean) data.get('success');
                result.recordsProcessed = (Integer) data.get('recordsProcessed');
                
                if (data.containsKey('errors')) {
                    List<Object> apiErrors = (List<Object>) data.get('errors');
                    if (apiErrors != null && !apiErrors.isEmpty()) {
                        result.success = false;
                        for (Object error : apiErrors) {
                            result.errors.add(String.valueOf(error));
                        }
                    }
                }
                
                result.message = result.success 
                    ? 'Успешно обработано: ' + result.recordsProcessed + ' записей'
                    : 'Ошибка: ' + String.join(result.errors, '; ');
                    
                addLog(result, result.success ? 'SUCCESS' : 'ERROR', result.message);
            } else {
                result.success = false;
                result.message = 'HTTP ' + response.getStatusCode() + ': ' + response.getStatus();
                addLog(result, 'ERROR', result.message);
            }
        } catch (Exception e) {
            result.success = false;
            result.message = 'Ошибка: ' + e.getMessage();
            result.errors.add(e.getTypeName() + ': ' + e.getMessage());
            addLog(result, 'ERROR', result.message);
        }
        
        return finalize(result, startTime);
    }
    
    /**
     * Завершение синхронизации - расчет длительности
     */
    private static SyncResult finalize(SyncResult result, Datetime startTime) {
        result.duration = (Datetime.now().getTime() - startTime.getTime()) / 1000.0;
        return result;
    }
    
    /**
     * Синхронизация из PostgreSQL в Salesforce
     */
    public static SyncResult syncFromPostgreSQL(ObjectType objType, Map<String, Object> filters) {
        SyncResult result = new SyncResult();
        result.objectType = objType.name();
        result.direction = 'FROM_POSTGRES';
        Datetime startTime = Datetime.now();
        
        addLog(result, 'INFO', 'Начало синхронизации из PostgreSQL');
        
        try {
            HttpResponse response = callPostgreSQLAPI('fetch', new Map<String, Object>{
                'objectType' => objType.name(),
                'filters' => filters
            });
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                List<Object> records = (List<Object>) data.get('records');
                
                if (records == null || records.isEmpty()) {
                    result.success = true;
                    result.message = 'Нет записей для синхронизации';
                    addLog(result, 'INFO', result.message);
                    return finalize(result, startTime);
                }
                
                List<SObject> salesforceRecords = convertToSalesforceRecords(records, objType);
                Database.UpsertResult[] upsertResults = upsertRecords(salesforceRecords, objType);
                
                Integer successCount = 0;
                for (Database.UpsertResult ur : upsertResults) {
                    if (ur.isSuccess()) {
                        successCount++;
                    } else {
                        result.recordsFailed++;
                        result.errors.add(ur.getErrors()[0].getMessage());
                    }
                }
                
                result.success = result.recordsFailed == 0;
                result.recordsProcessed = successCount;
                result.message = 'Обработано: ' + successCount + 
                    (result.recordsFailed > 0 ? ', ошибок: ' + result.recordsFailed : '');
                addLog(result, result.success ? 'SUCCESS' : 'ERROR', result.message);
            } else {
                result.success = false;
                result.message = 'HTTP ' + response.getStatusCode();
                addLog(result, 'ERROR', result.message);
            }
        } catch (Exception e) {
            result.success = false;
            result.message = 'Ошибка: ' + e.getMessage();
            result.errors.add(e.getTypeName() + ': ' + e.getMessage());
            addLog(result, 'ERROR', result.message);
        }
        
        return finalize(result, startTime);
    }
    
    /**
     * Двусторонняя синхронизация
     */
    public static SyncResult syncBidirectional(ObjectType objType, List<Id> recordIds, Map<String, Object> filters) {
        SyncResult result = new SyncResult();
        result.objectType = objType.name();
        result.direction = 'BIDIRECTIONAL';
        Datetime startTime = Datetime.now();
        
        addLog(result, 'INFO', 'Начало двусторонней синхронизации');
        
        SyncResult toPostgres = syncToPostgreSQL(objType, recordIds);
        SyncResult fromPostgres = syncFromPostgreSQL(objType, filters);
        
        // Объединяем результаты
        result.success = toPostgres.success && fromPostgres.success;
        result.recordsProcessed = toPostgres.recordsProcessed + fromPostgres.recordsProcessed;
        result.recordsFailed = toPostgres.recordsFailed + fromPostgres.recordsFailed;
        
        result.logEntries.addAll(toPostgres.logEntries);
        result.logEntries.addAll(fromPostgres.logEntries);
        result.errors.addAll(toPostgres.errors);
        result.errors.addAll(fromPostgres.errors);
        
        result.message = result.success 
            ? 'Успешно. В PG: ' + toPostgres.recordsProcessed + ', из PG: ' + fromPostgres.recordsProcessed
            : 'Ошибка. ' + String.join(result.errors, '; ');
            
        addLog(result, result.success ? 'SUCCESS' : 'ERROR', result.message);
        
        return finalize(result, startTime);
    }
    
    /**
     * Запрос записей из Salesforce
     */
    private static List<SObject> queryRecords(ObjectType objType, List<Id> recordIds) {
        String soql = buildSOQL(objType, recordIds);
        return Database.query(soql);
    }
    
    /**
     * Построение SOQL запроса
     */
    private static String buildSOQL(ObjectType objType, List<Id> recordIds) {
        Map<ObjectType, String> fieldMappings = new Map<ObjectType, String>{
            ObjectType.LEAD => 'SELECT Id, FirstName, LastName, Email, Phone, Company, Status, LeadSource, CreatedDate, LastModifiedDate FROM Lead',
            ObjectType.CONTACT => 'SELECT Id, FirstName, LastName, Email, Phone, AccountId, Title, CreatedDate, LastModifiedDate FROM Contact',
            ObjectType.OPPORTUNITY => 'SELECT Id, Name, Amount, StageName, CloseDate, AccountId, Type, LeadSource, CreatedDate, LastModifiedDate FROM Opportunity'
        };
        
        String baseQuery = fieldMappings.get(objType);
        if (recordIds != null && !recordIds.isEmpty()) {
            baseQuery += ' WHERE Id IN :recordIds';
        }
        baseQuery += ' ORDER BY LastModifiedDate DESC LIMIT 1000';
        
        return baseQuery;
    }
    
    /**
     * Подготовка данных для отправки в PostgreSQL
     */
    private static List<Map<String, Object>> preparePayload(List<SObject> records, ObjectType objType) {
        List<Map<String, Object>> payload = new List<Map<String, Object>>();
        
        for (SObject record : records) {
            Map<String, Object> recordMap = new Map<String, Object>();
            recordMap.put('salesforceId', record.Id);
            recordMap.put('objectType', objType.name());
            recordMap.put('lastModified', record.get('LastModifiedDate'));
            
            // Маппинг полей в зависимости от типа объекта
            if (objType == ObjectType.LEAD) {
                Lead lead = (Lead) record;
                recordMap.put('firstName', lead.FirstName);
                recordMap.put('lastName', lead.LastName);
                recordMap.put('email', lead.Email);
                recordMap.put('phone', lead.Phone);
                recordMap.put('company', lead.Company);
                recordMap.put('status', lead.Status);
                recordMap.put('leadSource', lead.LeadSource);
            } else if (objType == ObjectType.CONTACT) {
                Contact contact = (Contact) record;
                recordMap.put('firstName', contact.FirstName);
                recordMap.put('lastName', contact.LastName);
                recordMap.put('email', contact.Email);
                recordMap.put('phone', contact.Phone);
                recordMap.put('accountId', contact.AccountId);
                recordMap.put('title', contact.Title);
            } else if (objType == ObjectType.OPPORTUNITY) {
                Opportunity opp = (Opportunity) record;
                recordMap.put('name', opp.Name);
                recordMap.put('amount', opp.Amount);
                recordMap.put('stageName', opp.StageName);
                recordMap.put('closeDate', opp.CloseDate);
                recordMap.put('accountId', opp.AccountId);
                recordMap.put('type', opp.Type);
                recordMap.put('leadSource', opp.LeadSource);
            }
            
            payload.add(recordMap);
        }
        
        return payload;
    }
    
    /**
     * Конвертация данных из PostgreSQL в объекты Salesforce
     */
    private static List<SObject> convertToSalesforceRecords(List<Object> records, ObjectType objType) {
        List<SObject> salesforceRecords = new List<SObject>();
        
        for (Object recordObj : records) {
            Map<String, Object> record = (Map<String, Object>) recordObj;
            
            if (objType == ObjectType.LEAD) {
                Lead lead = new Lead();
                if (record.containsKey('salesforceId')) {
                    lead.Id = (String) record.get('salesforceId');
                }
                lead.FirstName = (String) record.get('firstName');
                lead.LastName = (String) record.get('lastName');
                lead.Email = (String) record.get('email');
                lead.Phone = (String) record.get('phone');
                lead.Company = (String) record.get('company');
                lead.Status = (String) record.get('status');
                lead.LeadSource = (String) record.get('leadSource');
                salesforceRecords.add(lead);
            } else if (objType == ObjectType.CONTACT) {
                Contact contact = new Contact();
                if (record.containsKey('salesforceId')) {
                    contact.Id = (String) record.get('salesforceId');
                }
                contact.FirstName = (String) record.get('firstName');
                contact.LastName = (String) record.get('lastName');
                contact.Email = (String) record.get('email');
                contact.Phone = (String) record.get('phone');
                contact.AccountId = (String) record.get('accountId');
                contact.Title = (String) record.get('title');
                salesforceRecords.add(contact);
            } else if (objType == ObjectType.OPPORTUNITY) {
                Opportunity opp = new Opportunity();
                if (record.containsKey('salesforceId')) {
                    opp.Id = (String) record.get('salesforceId');
                }
                opp.Name = (String) record.get('name');
                if (record.containsKey('amount') && record.get('amount') != null) {
                    opp.Amount = (Decimal) record.get('amount');
                }
                opp.StageName = (String) record.get('stageName');
                if (record.containsKey('closeDate') && record.get('closeDate') != null) {
                    Object closeDateObj = record.get('closeDate');
                    if (closeDateObj instanceof String) {
                        opp.CloseDate = Date.valueOf((String) closeDateObj);
                    } else if (closeDateObj instanceof Date) {
                        opp.CloseDate = (Date) closeDateObj;
                    }
                }
                opp.AccountId = (String) record.get('accountId');
                opp.Type = (String) record.get('type');
                opp.LeadSource = (String) record.get('leadSource');
                salesforceRecords.add(opp);
            }
        }
        
        return salesforceRecords;
    }
    
    /**
     * Upsert записей в Salesforce
     */
    private static Database.UpsertResult[] upsertRecords(List<SObject> records, ObjectType objType) {
        Schema.SObjectField externalIdField;
        
        if (objType == ObjectType.LEAD) {
            externalIdField = Lead.Id;
        } else if (objType == ObjectType.CONTACT) {
            externalIdField = Contact.Id;
        } else if (objType == ObjectType.OPPORTUNITY) {
            externalIdField = Opportunity.Id;
        }
        
        return Database.upsert(records, externalIdField, false);
    }
    
    /**
     * Вызов API PostgreSQL
     */
    private static HttpResponse callPostgreSQLAPI(String action, Object payload) {
        HttpRequest req = new HttpRequest();
        
        // Прямой URL для ngrok
        String baseUrl = 'https://hadley-chronogrammatical-rememberingly.ngrok-free.dev';
        String endpoint = baseUrl + '/' + action;
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        
        // Добавляем заголовки для ngrok
        req.setHeader('ngrok-skip-browser-warning', 'true');
        
        // Сериализуем payload
        String body = JSON.serialize(payload);
        req.setBody(body);
        req.setTimeout(120000);
        
        Http http = new Http();
        HttpResponse response = http.send(req);
        
        return response;
    }
    
    /**
     * Класс результата синхронизации
     */
    public class SyncResult {
        @AuraEnabled public String objectType;
        @AuraEnabled public String direction;
        @AuraEnabled public Boolean success;
        @AuraEnabled public Integer recordsProcessed;
        @AuraEnabled public Integer recordsFailed;
        @AuraEnabled public String message;
        @AuraEnabled public List<String> errors;
        @AuraEnabled public List<SyncLogEntry> logEntries;
        @AuraEnabled public Decimal duration;
        
        public SyncResult() {
            this.errors = new List<String>();
            this.logEntries = new List<SyncLogEntry>();
            this.recordsProcessed = 0;
            this.recordsFailed = 0;
            this.success = false;
        }
    }
    
    /**
     * Класс записи лога
     */
    public class SyncLogEntry {
        @AuraEnabled public String timestamp;
        @AuraEnabled public String level;
        @AuraEnabled public String message;
        
        public SyncLogEntry(String level, String message) {
            this.timestamp = Datetime.now().format('yyyy-MM-dd HH:mm:ss');
            this.level = level;
            this.message = message;
        }
    }
    
    /**
     * Добавление записи в лог
     */
    private static void addLog(SyncResult result, String level, String message) {
        result.logEntries.add(new SyncLogEntry(level, message));
    }
}