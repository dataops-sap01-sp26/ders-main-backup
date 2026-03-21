// ═══════════════════════════════════════════════════════════════════════════════
// ROOT PROJECTION VIEW: Report Catalog (Fiori UI)
// PURPOSE: List Report for browsing available reports (US-E1-001)
// NAMING: ZCR_ = Z + C(Consumption) + R(Root) per FPT Naming Convention
// ═══════════════════════════════════════════════════════════════════════════════
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Report Catalog'
@Metadata.ignorePropagatedAnnotations: false
@Metadata.allowExtensions: true
@Search.searchable: true

@UI.headerInfo: {
  typeName: 'Report',
  typeNamePlural: 'Reports',
  title: { type: #STANDARD, value: 'ReportName' },
  description: { type: #STANDARD, value: 'Description' }
}

@UI.presentationVariant: [{
  sortOrder: [{ by: 'SortOrder', direction: #ASC },
              { by: 'ModuleId', direction: #ASC }],
  visualizations: [{ type: #AS_LINEITEM }]
}]

define root view entity ZCR_DRS_CATALOG
  provider contract transactional_query
  as projection on ZIR_DRS_CATALOG
{
      // ═══════════════════════════════════════════════════════════════════════════
      // PRIMARY KEY
      // ═══════════════════════════════════════════════════════════════════════════
      @UI.facet: [
        // Header Facet - Status
        { id: 'StatusHeader', purpose: #HEADER, type: #DATAPOINT_REFERENCE,
          targetQualifier: 'StatusDP', position: 10 },
        // General Info
        { id: 'GeneralInfo', label: 'General Information', type: #COLLECTION, position: 10 },
        { id: 'BasicData', parentId: 'GeneralInfo', label: 'Basic Data',
          type: #IDENTIFICATION_REFERENCE, position: 10 },
        // Technical Config
        { id: 'TechConfig', label: 'Technical Configuration',
          type: #IDENTIFICATION_REFERENCE, position: 20, targetQualifier: 'TechInfo' },
        // Admin Section (collapsible)
        { id: 'AdminInfo', label: 'Administrative', type: #IDENTIFICATION_REFERENCE,
          position: 30, targetQualifier: 'AdminInfo' }
      ]

      @UI.lineItem: [
        { position: 10, importance: #HIGH },
        { type: #FOR_ACTION, dataAction: 'previewReport', label: 'Preview', position: 5, importance: #HIGH }
      ]
      @UI.identification: [{ position: 10 }]
      @UI.selectionField: [{ position: 10 }]
      @Search.defaultSearchElement: true
      key ReportId,

      // ═══════════════════════════════════════════════════════════════════════════
      // CLASSIFICATION
      // ═══════════════════════════════════════════════════════════════════════════
      @UI.lineItem: [{ position: 20, importance: #HIGH }]
      @UI.identification: [{ position: 20 }]
      @UI.selectionField: [{ position: 20 }]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_VH_DRS_MODULE', element: 'ModuleId' } }]
      ModuleId,

      // ═══════════════════════════════════════════════════════════════════════════
      // REPORT METADATA
      // ═══════════════════════════════════════════════════════════════════════════
      @UI.lineItem: [{ position: 30, importance: #HIGH }]
      @UI.identification: [{ position: 40 }]
      @Search.defaultSearchElement: true
      ReportName,

      @UI.lineItem: [{ position: 40, importance: #MEDIUM }]
      @UI.identification: [{ position: 50 }]
      @Search.defaultSearchElement: true
      Description,

      @UI.identification: [{ position: 60 }]
      @UI.multiLineText: true
      LongText,

      // ═══════════════════════════════════════════════════════════════════════════
      // TECHNICAL CONFIGURATION
      // ═══════════════════════════════════════════════════════════════════════════
      @UI.identification: [{ position: 10, qualifier: 'TechInfo' }]
      CdsViewName,

      @UI.identification: [{ position: 20, qualifier: 'TechInfo' }]
      ReportClass,

      // ═══════════════════════════════════════════════════════════════════════════
      // STATUS
      // ═══════════════════════════════════════════════════════════════════════════
      @UI.lineItem: [{ position: 60, importance: #HIGH, criticality: 'StatusCriticality' }]
      @UI.dataPoint: { qualifier: 'StatusDP', title: 'Status', criticality: 'StatusCriticality' }
      @UI.identification: [{ position: 70 }]
      @UI.selectionField: [{ position: 30 }]
      IsActive,

      @UI.hidden: true
      SortOrder,

      // Virtual field for status criticality (from root entity)
      @UI.hidden: true
      StatusCriticality,

      // ═══════════════════════════════════════════════════════════════════════════
      // ADMINISTRATIVE FIELDS
      // ═══════════════════════════════════════════════════════════════════════════
      @UI.identification: [{ position: 10, qualifier: 'AdminInfo' }]
      CreatedBy,

      @UI.identification: [{ position: 20, qualifier: 'AdminInfo' }]
      CreatedAt,

      @UI.identification: [{ position: 30, qualifier: 'AdminInfo' }]
      LastChangedBy,

      @UI.identification: [{ position: 40, qualifier: 'AdminInfo' }]
      LastChangedAt,

      @UI.hidden: true
      LocalLastChangedAt,

      // ═══════════════════════════════════════════════════════════════════════════
      // ASSOCIATIONS
      // ═══════════════════════════════════════════════════════════════════════════
      _Module
}
