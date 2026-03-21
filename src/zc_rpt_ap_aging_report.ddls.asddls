@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection View for AP Aging Report'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true 
@Search.searchable: true

define root view entity ZC_RPT_AP_AGING_REPORT
  as select from ZI_RPT_AP_AGING_REPORT
  association [0..*] to ZC_RPT_AP_AGING_REPORT_I as _Items
    on  $projection.CompanyCode = _Items.CompanyCode
    and $projection.Supplier    = _Items.Supplier
{
      @Search.defaultSearchElement: true
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CompanyCode', element: 'CompanyCode' } }]
      @Consumption.filter: { mandatory: true, selectionType: #SINGLE, multipleSelections: false }
  key CompanyCode,

      @Search.defaultSearchElement: true
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Supplier', element: 'Supplier' } }]
  key Supplier,

  key LocalCurrency,
  
      SupplierName,
    
      @Aggregation.default: #SUM
      sum( OriginalAmount ) as TotalAmount,

      sum( Bucket_NotDue )  as Bucket_NotDue,
      sum( Bucket_0_30 )    as Bucket_0_30,
      sum( Bucket_31_60 )   as Bucket_31_60,
      sum( Bucket_61_90 )   as Bucket_61_90,
      sum( Bucket_Over_90 ) as Bucket_Over_90,

      _Items
}
group by
    CompanyCode,
    Supplier,
    SupplierName,
    LocalCurrency
