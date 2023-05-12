/* Code snippet to bulk assign object and field level security 
   for multiple objects to a permission set. */


// ID of the PS
Id permissionSetId = '0PS2f0000003KLy';
List<ObjectPermissions> opList = new List<ObjectPermissions>();

// Getting all the objects which already have read access in the PS, so that those objects are excluded from the operation
// Filter can be changed based on requirements
List<ObjectPermissions> existingOp = [Select SobjectType, PermissionsRead 
                                     FROM ObjectPermissions
                                     WHERE PermissionsRead = true AND ParentId = :permissionSetId];

// List of objects for which the permission and FLS has to be set. Replace this based on the requirements. 
List<String> objectAPINames = new List<String>{'vlocity_cmt__OmniUserSession__c',
                                                'vlocity_cmt__OperatingHours__c',
                                                'vlocity_cmt__OrchestrationPlanDefinition__c',
                                                'vlocity_cmt__OrchestrationQueue__c',
                                                'vlocity_cmt__OrchestrationQueueAssignmentRule__c',
                                                'vlocity_cmt__OrchestrationScenario__c',
                                                'vlocity_cmt__OrchestrationSchedulerImplementation__c',
                                                'vlocity_cmt__PicklistSelectionEntry__c',
                                                'vlocity_cmt__PriceListEntry__c',
                                                'vlocity_cmt__PricingComponent__c',
                                                'vlocity_cmt__PricingComponentRelationship__c',
                                                'vlocity_cmt__AttributeAssignmentExport__c',
                                                'vlocity_cmt__CachedAPIResponseOffers__c',
                                                'vlocity_cmt__CatalogProductRelationship__c',
                                                'vlocity_cmt__DocumentTemplateElement__c',
                                                'vlocity_cmt__DocumentTemplateSection__c',
                                                'vlocity_cmt__DocumentTemplateSectionCondition__c',
                                                'vlocity_cmt__ErrorCode__c',
                                                'vlocity_cmt__Error_Code__c',
                                                'vlocity_cmt__GenericDocument__c',
                                                'vlocity_cmt__GenericRecipient__c',
                                                'vlocity_cmt__InterfaceImplementationDetail__c',
                                                'vlocity_cmt__ManualQueueMember__c',
                                                'vlocity_cmt__OfferMigrationComponentMapping__c',
                                                'vlocity_cmt__OperatingHoursEntry__c',
                                                'vlocity_cmt__OrchestrationDependencyDefinition__c',
                                                'vlocity_cmt__OrchestrationItemDefinition__c',
                                                'vlocity_cmt__PriceListEntry__c',
                                                'vlocity_cmt__PricingPlanStep__c',
                                                'vlocity_cmt__PricingVariableBinding__c',
                                                'vlocity_cmt__ProfilingSegment__c',
                                                'vlocity_cmt__ProjectItem__c'};

// Adding all the existing object names in lower case in a list
List<String> existingObjects = new List<String>();
for(ObjectPermissions op: existingOp){
    String objectName = op.SobjectType.toLowerCase();
    existingObjects.add(objectName);
}
System.debug('existingObjects - ' + existingObjects);

List<FieldPermissions> fpList = new List<FieldPermissions>();
for (String SobjectApiName : objectAPINames){  

    Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    Map<String, Schema.SObjectField> fieldMap = schemaMap.get(SobjectApiName).getDescribe().fields.getMap();
    
    // If object access is not there already, create an ObjectPermission instance and add it in a list
    if(!existingObjects.contains(SobjectApiName.toLowerCase())){
        ObjectPermissions op = new ObjectPermissions();
        op.SobjectType = SobjectApiName;
        op.PermissionsRead = true;
        op.ParentId = permissionSetId;
        opList.add(op);
    }
    
    // Get all the fields that already have access
    List<FieldPermissions> existingFp = [SELECT SobjectType, Field, PermissionsRead, ParentId
                                         FROM FieldPermissions 
                                         WHERE SobjectType = :SobjectApiName AND PermissionsRead = true
                                         AND ParentId = :permissionSetId];
    
    System.debug('existingFp - ' +  existingFp);
    List<String> existingFields = new List<String>();
    for(FieldPermissions fp: existingFp){
        String fieldName = fp.Field.subStringAfter('.').toLowerCase();
        existingFields.add(fieldName);
    }
    System.debug('existingFields - ' + existingFields);  
    
    // If FLS is not there already, create an instance of FieldPermissions and add to a list.
    // isCustom() check can be removed based on the requirements.
    for(String fieldName : fieldMap.keyset()){	
        Boolean isCustom = fieldMap.get(fieldName).getDescribe().isCustom();
        if(isCustom && !existingFields.contains(fieldName.toLowerCase())){
            System.debug('inside if for field - ' + fieldName);
            FieldPermissions fp = new FieldPermissions();
            fp.ParentId = permissionSetId;
            fp.Field = SobjectApiName + '.' + fieldName;
            System.debug('FieldName - ' + fp.Field);
            fp.PermissionsRead = true;
            fp.SobjectType = SobjectApiName;
            fpList.add(fp);
        }
    }
    
}
System.debug('fpList - ' + fpList);
System.debug('opList - ' + opList);

// Insert the ObjectPermissions and FieldPermissions records
Database.insert(fpList, false);
Database.insert(opList, false);

