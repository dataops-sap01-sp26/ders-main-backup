@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Subscription Projection'
@Metadata.ignorePropagatedAnnotations: false
@Metadata.allowExtensions: true

// ═══════════════════════════════════════════════════════════════════════════════
// SUBSCRIPTION PROJECTION: Fiori UI with report-specific parameter facets
// ═══════════════════════════════════════════════════════════════════════════════
define root view entity ZCR_DRS_SUBSCR
provider contract transactional_query
  as projection on ZIR_DRS_SUBSCR
{
    key SubscrUuid,
    key SubscrId,
    SubscrName,
    
    @Consumption.valueHelpDefinition: [{ entity: { name: 'ZIR_DRS_CATALOG', element: 'ReportId' } }]
    ReportId,
    
    @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CompanyCodeStdVH', element: 'CompanyCode' } }]
    Bukrs,
    
    @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_VH_DRS_FORMAT', element: 'FormatId' } }]
    OutputFormat,
    
    EmailTo,
    EmailCc,
    Status,
    StatusText,
    StatusCriticality,
    
    CreatedBy,
    CreatedAt,
    LastChangedBy,
    LastChangedAt,
    LocalLastChangedAt,
    @ObjectModel.virtualElement: true
    @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_DRS_SUBSCR_HIDE'
    virtual HideParamGL01 : abap_boolean,
    
    @ObjectModel.virtualElement: true
    @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_DRS_SUBSCR_HIDE'
    virtual HideParamAR01 : abap_boolean,
    
    /* Associations */
    _Catalog,
    _ParamGL01 : redirected to composition child ZC_DRS_PARAM_GL01,
    _ParamAR01 : redirected to composition child ZC_DRS_PARAM_AR01, 
    _ParamAR02 : redirected to composition child ZC_DRS_PARAM_AR02
}
