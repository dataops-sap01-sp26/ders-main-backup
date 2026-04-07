@AccessControl.authorizationCheck: #CHECK
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
  key     SubscrUuid,
  key     SubscrId,
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
  virtual HideParamGL01    : abap_boolean,

          @ObjectModel.virtualElement: true
          @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_DRS_SUBSCR_HIDE'
  virtual HideParamAR01    : abap_boolean,

          @ObjectModel.virtualElement: true
          @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_DRS_SUBSCR_HIDE'
  virtual HideParamAR02    : abap_boolean,

          @ObjectModel.virtualElement: true
          @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_DRS_SUBSCR_HIDE'
  virtual HideParamAR03    : abap_boolean,

          @ObjectModel.virtualElement: true
          @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_DRS_SUBSCR_HIDE'
  virtual HideParamAP01    : abap_boolean,

          @ObjectModel.virtualElement: true
          @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_DRS_SUBSCR_HIDE'
  virtual HideParamAP02    : abap_boolean,

          @ObjectModel.virtualElement: true
          @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_DRS_SUBSCR_HIDE'
  virtual HideParamAP03    : abap_boolean,

          @ObjectModel.virtualElement: true
          @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_DRS_SUBSCR_HIDE'
  virtual HideCustomerList : abap_boolean,

          @ObjectModel.virtualElement: true
          @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_DRS_SUBSCR_HIDE'
  virtual HideVendorList   : abap_boolean,



          /* Associations */
          _Catalog,
          _ParamGL01 : redirected to composition child ZC_DRS_PARAM_GL01,
          _ParamAR01 : redirected to composition child ZC_DRS_PARAM_AR01,
          _ParamAR02 : redirected to composition child ZC_DRS_PARAM_AR02,
          _ParamAR03 : redirected to composition child ZC_DRS_PARAM_AR03,
          _ParamAP01 : redirected to composition child ZC_DRS_PARAM_AP01,
          _ParamAP02 : redirected to composition child ZC_DRS_PARAM_AP02,
          _ParamAP03 : redirected to composition child ZC_DRS_PARAM_AP03,
          _Customers : redirected to composition child ZC_DRS_CUSTOMERS,
          _Vendors   : redirected to composition child ZC_DRS_VENDORS,
          _JobConfig : redirected to ZCR_DRS_JOB_CONFIG
}
