/**
 * ÐÐ¾Ð½ÑÑÐ¾Ð»Ð»ÐµÑ Ð´Ð»Ñ LWC ÐºÐ¾Ð¼Ð¿Ð¾Ð½ÐµÐ½ÑÐ° ÑÐ¸Ð½ÑÑÐ¾Ð½Ð¸Ð·Ð°ÑÐ¸Ð¸
 */
public with sharing class SyncController {// 222 222
    
    /**
     * Ð¡Ð¸Ð½ÑÑÐ¾Ð½Ð¸Ð·Ð°ÑÐ¸Ñ Ð² PostgreSQL
     */
    @AuraEnabled
    public static SyncService.SyncResult syncToPostgreSQL(String objectType, List<String> recordIds) {
        try {
            SyncService.ObjectType objType = getObjectType(objectType);
            List<Id> ids = new List<Id>();
            if (recordIds != null) {
                for (String recordId : recordIds) {
                    ids.add(Id.valueOf(recordId));
                }
            }
            SyncService.SyncResult result = SyncService.syncToPostgreSQL(objType, ids);
            if (result == null) {
                result = new SyncService.SyncResult();
                result.success = false;
                result.message = 'ÐÑÐ¸Ð±ÐºÐ°: ÑÐµÐ·ÑÐ»ÑÑÐ°Ñ ÑÐ¸Ð½ÑÑÐ¾Ð½Ð¸Ð·Ð°ÑÐ¸Ð¸ Ð¿ÑÑÑÐ¾Ð¹';
            }
            return result;
        } catch (Exception e) {
            SyncService.SyncResult errorResult = new SyncService.SyncResult();
            errorResult.success = false;
            errorResult.message = 'ÐÑÐ¸Ð±ÐºÐ°: ' + e.getMessage();
            errorResult.errors = new List<String>{ e.getTypeName() + ': ' + e.getMessage() };
            errorResult.logEntries = new List<SyncService.SyncLogEntry>();
            errorResult.logEntries.add(new SyncService.SyncLogEntry('ERROR', 'ÐÑÐºÐ»ÑÑÐµÐ½Ð¸Ðµ: ' + e.getMessage()));
            return errorResult;
        }
    }
    
    /**
     * Ð¡Ð¸Ð½ÑÑÐ¾Ð½Ð¸Ð·Ð°ÑÐ¸Ñ Ð¸Ð· PostgreSQL
     */
    @AuraEnabled
    public static SyncService.SyncResult syncFromPostgreSQL(String objectType, Map<String, Object> filters) {
        try {
            SyncService.ObjectType objType = getObjectType(objectType);
            SyncService.SyncResult result = SyncService.syncFromPostgreSQL(objType, filters);
            if (result == null) {
                result = new SyncService.SyncResult();
                result.success = false;
                result.message = 'ÐÑÐ¸Ð±ÐºÐ°: ÑÐµÐ·ÑÐ»ÑÑÐ°Ñ ÑÐ¸Ð½ÑÑÐ¾Ð½Ð¸Ð·Ð°ÑÐ¸Ð¸ Ð¿ÑÑÑÐ¾Ð¹';
            }
            return result;
        } catch (Exception e) {
            SyncService.SyncResult errorResult = new SyncService.SyncResult();
            errorResult.success = false;
            errorResult.message = 'ÐÑÐ¸Ð±ÐºÐ°: ' + e.getMessage();
            errorResult.errors = new List<String>{ e.getTypeName() + ': ' + e.getMessage() };
            errorResult.logEntries = new List<SyncService.SyncLogEntry>();
            errorResult.logEntries.add(new SyncService.SyncLogEntry('ERROR', 'ÐÑÐºÐ»ÑÑÐµÐ½Ð¸Ðµ: ' + e.getMessage()));
            return errorResult;
        }
    }
    
    /**
     * ÐÐ²ÑÑÑÐ¾ÑÐ¾Ð½Ð½ÑÑ ÑÐ¸Ð½ÑÑÐ¾Ð½Ð¸Ð·Ð°ÑÐ¸Ñ
     */
    @AuraEnabled
    public static SyncService.SyncResult syncBidirectional(String objectType, List<String> recordIds, Map<String, Object> filters) {
        try {
            SyncService.ObjectType objType = getObjectType(objectType);
            List<Id> ids = new List<Id>();
            if (recordIds != null) {
                for (String recordId : recordIds) {
                    ids.add(Id.valueOf(recordId));
                }
            }
            SyncService.SyncResult result = SyncService.syncBidirectional(objType, ids, filters);
            
            // Ð£Ð±ÐµÐ¶Ð´Ð°ÐµÐ¼ÑÑ, ÑÑÐ¾ Ð²ÑÐµ Ð¿Ð¾Ð»Ñ Ð¸Ð½Ð¸ÑÐ¸Ð°Ð»Ð¸Ð·Ð¸ÑÐ¾Ð²Ð°Ð½Ñ
            if (result == null) {
                result = new SyncService.SyncResult();
                result.success = false;
                result.message = 'ÐÑÐ¸Ð±ÐºÐ°: ÑÐµÐ·ÑÐ»ÑÑÐ°Ñ ÑÐ¸Ð½ÑÑÐ¾Ð½Ð¸Ð·Ð°ÑÐ¸Ð¸ Ð¿ÑÑÑÐ¾Ð¹';
            }
            
            return result;
        } catch (Exception e) {
            // ÐÐ±ÑÐ°Ð±Ð¾ÑÐºÐ° Ð¸ÑÐºÐ»ÑÑÐµÐ½Ð¸Ð¹
            SyncService.SyncResult errorResult = new SyncService.SyncResult();
            errorResult.success = false;
            errorResult.message = 'ÐÑÐ¸Ð±ÐºÐ°: ' + e.getMessage();
            errorResult.errors = new List<String>{ e.getTypeName() + ': ' + e.getMessage() };
            errorResult.logEntries = new List<SyncService.SyncLogEntry>();
            errorResult.logEntries.add(new SyncService.SyncLogEntry('ERROR', 'ÐÑÐºÐ»ÑÑÐµÐ½Ð¸Ðµ: ' + e.getMessage()));
            return errorResult;
        }
    }
    
    /**
     * ÐÐ¾Ð»ÑÑÐµÐ½Ð¸Ðµ Ð·Ð°Ð¿Ð¸ÑÐµÐ¹ Ð´Ð»Ñ Ð¾ÑÐ¾Ð±ÑÐ°Ð¶ÐµÐ½Ð¸Ñ
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getRecords(String objectType, Map<String, Object> filters, Integer limitCount) {
        SyncService.ObjectType objType = getObjectType(objectType);
        List<SObject> records = queryRecordsWithFilters(objType, filters, limitCount);
        
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (SObject record : records) {
            Map<String, Object> recordMap = new Map<String, Object>();
            recordMap.put('Id', record.Id);
            
            if (objType == SyncService.ObjectType.LEAD) {
                Lead lead = (Lead) record;
                recordMap.put('Name', (lead.FirstName != null ? lead.FirstName : '') + ' ' + (lead.LastName != null ? lead.LastName : ''));
                recordMap.put('Email', lead.Email);
                recordMap.put('Phone', lead.Phone);
                recordMap.put('Company', lead.Company);
                recordMap.put('Status', lead.Status);
            } else if (objType == SyncService.ObjectType.CONTACT) {
                Contact contact = (Contact) record;
                recordMap.put('Name', (contact.FirstName != null ? contact.FirstName : '') + ' ' + (contact.LastName != null ? contact.LastName : ''));
                recordMap.put('Email', contact.Email);
                recordMap.put('Phone', contact.Phone);
                recordMap.put('Title', contact.Title);
            } else if (objType == SyncService.ObjectType.OPPORTUNITY) {
                Opportunity opp = (Opportunity) record;
                recordMap.put('Name', opp.Name);
                recordMap.put('Amount', opp.Amount);
                recordMap.put('StageName', opp.StageName);
                recordMap.put('CloseDate', opp.CloseDate);
            }
            
            recordMap.put('LastModifiedDate', record.get('LastModifiedDate'));
            result.add(recordMap);
        }
        
        return result;
    }
    
    private static List<SObject> queryRecordsWithFilters(SyncService.ObjectType objType, Map<String, Object> filters, Integer limitCount) {
        Map<SyncService.ObjectType, String> baseQueries = new Map<SyncService.ObjectType, String>{
            SyncService.ObjectType.LEAD => 'SELECT Id, FirstName, LastName, Email, Phone, Company, Status, LastModifiedDate FROM Lead',
            SyncService.ObjectType.CONTACT => 'SELECT Id, FirstName, LastName, Email, Phone, Title, LastModifiedDate FROM Contact',
            SyncService.ObjectType.OPPORTUNITY => 'SELECT Id, Name, Amount, StageName, CloseDate, LastModifiedDate FROM Opportunity'
        };
        
        String soql = baseQueries.get(objType);
        List<String> conditions = new List<String>();
        Map<String, Object> bindVars = new Map<String, Object>();
        
        if (filters != null) {
            if (filters.containsKey('searchText') && String.isNotBlank((String) filters.get('searchText'))) {
                String searchText = '%' + String.escapeSingleQuotes((String) filters.get('searchText')) + '%';
                if (objType == SyncService.ObjectType.LEAD) {
                    conditions.add('(FirstName LIKE \'' + searchText + '\' OR LastName LIKE \'' + searchText + '\' OR Email LIKE \'' + searchText + '\' OR Company LIKE \'' + searchText + '\')');
                } else if (objType == SyncService.ObjectType.CONTACT) {
                    conditions.add('(FirstName LIKE \'' + searchText + '\' OR LastName LIKE \'' + searchText + '\' OR Email LIKE \'' + searchText + '\')');
                } else if (objType == SyncService.ObjectType.OPPORTUNITY) {
                    conditions.add('Name LIKE \'' + searchText + '\'');
                }
            }
            
            if (filters.containsKey('dateFrom') && filters.get('dateFrom') != null) {
                String dateFrom = (String) filters.get('dateFrom');
                conditions.add('LastModifiedDate >= ' + dateFrom + 'T00:00:00Z');
            }
            
            if (filters.containsKey('dateTo') && filters.get('dateTo') != null) {
                String dateTo = (String) filters.get('dateTo');
                conditions.add('LastModifiedDate <= ' + dateTo + 'T23:59:59Z');
            }
        }
        
        if (!conditions.isEmpty()) {
            soql += ' WHERE ' + String.join(conditions, ' AND ');
        }
        
        soql += ' ORDER BY LastModifiedDate DESC';
        soql += ' LIMIT ' + (limitCount != null ? limitCount : 100);
        
        return Database.query(soql);
    }
    
    /**
     * ÐÐ¾Ð»ÑÑÐµÐ½Ð¸Ðµ ÑÑÐ°ÑÐ¸ÑÑÐ¸ÐºÐ¸ ÑÐ¸Ð½ÑÑÐ¾Ð½Ð¸Ð·Ð°ÑÐ¸Ð¸
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getSyncStatistics(String objectType) {
        SyncService.ObjectType objType = getObjectType(objectType);
        String soql = buildCountSOQL(objType);
        AggregateResult[] results = Database.query(soql);
        
        Map<String, Integer> stats = new Map<String, Integer>();
        for (AggregateResult ar : results) {
            String key = (String) ar.get('key');
            Integer count = (Integer) ar.get('cnt');
            stats.put(key, count);
        }
        
        return stats;
    }
    
    private static SyncService.ObjectType getObjectType(String objectType) {
        if (objectType == 'LEAD') {
            return SyncService.ObjectType.LEAD;
        } else if (objectType == 'CONTACT') {
            return SyncService.ObjectType.CONTACT;
        } else if (objectType == 'OPPORTUNITY') {
            return SyncService.ObjectType.OPPORTUNITY;
        }
        throw new AuraHandledException('ÐÐµÐ¸Ð·Ð²ÐµÑÑÐ½ÑÐ¹ ÑÐ¸Ð¿ Ð¾Ð±ÑÐµÐºÑÐ°: ' + objectType);
    }
    
    
    private static String buildCountSOQL(SyncService.ObjectType objType) {
        if (objType == SyncService.ObjectType.LEAD) {
            return 'SELECT Status key, COUNT(Id) cnt FROM Lead GROUP BY Status';
        } else if (objType == SyncService.ObjectType.CONTACT) {
            return 'SELECT Title key, COUNT(Id) cnt FROM Contact GROUP BY Title';
        } else if (objType == SyncService.ObjectType.OPPORTUNITY) {
            return 'SELECT StageName key, COUNT(Id) cnt FROM Opportunity GROUP BY StageName';
        }
        return '';
    }
}