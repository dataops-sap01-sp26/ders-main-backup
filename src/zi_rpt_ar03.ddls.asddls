@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface View for AR Aging Report'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true

define view entity ZI_RPT_AR03
  as select from ZI_RPT_AR03_BASE

  association [0..*] to ZI_RPT_AR03_I as _Items on  $projection.CompanyCode = _Items.CompanyCode
                                                and $projection.Customer    = _Items.Customer
{
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CompanyCode', element: 'CompanyCode' } }]
      @Consumption.filter: { mandatory: true, selectionType: #SINGLE, multipleSelections: false }
  key CompanyCode,

      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Customer', element: 'Customer' } }]
  key Customer,

  key LocalCurrency,

      CustomerName,

      @Aggregation.default: #SUM
      sum( OriginalAmount ) as TotalAmount,

      sum( Bucket_NotDue )  as Bucket_NotDue,
      sum( Bucket_0_30 )    as Bucket_0_30,
      sum( Bucket_31_60 )   as Bucket_31_60,
      sum( Bucket_61_90 )   as Bucket_61_90,
      sum( Bucket_Over_90 ) as Bucket_Over_90,

      max(NetDueDate)       as NetDueDate,

      _Items
}
group by
  CompanyCode,
  Customer,
  CustomerName,
  LocalCurrency
