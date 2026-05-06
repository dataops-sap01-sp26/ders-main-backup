// ═══════════════════════════════════════════════════════════════════════════════
// CUSTOM ENTITY: Current User Session Information
// PURPOSE: Returns current user info with PFCG roles (computed by query provider)
// PATTERN: Custom Entity - all data from ABAP class, no SQL source
// NAMING: ZIR_ = Z + I(Interface) + R(Root) per FPT Naming Convention
// NOTE: UI annotations inline (metadata extensions not supported for custom entities)
// ═══════════════════════════════════════════════════════════════════════════════
@EndUserText.label: 'Current User Session'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_USER_SESSION_QUERY'

@UI.headerInfo: {
  typeName: 'User Session',
  typeNamePlural: 'User Sessions',
  title: { type: #STANDARD, value: 'UserFullName' },
  description: { type: #STANDARD, value: 'RoleName' }
}

define custom entity ZIR_DRS_USER_SESSION
{
      // ═══════════════════════════════════════════════════════════════════════════
      // SINGLETON KEY
      // ═══════════════════════════════════════════════════════════════════════════
      @UI.facet       : [
        { id          : 'UserInfo',    purpose: #STANDARD, type: #FIELDGROUP_REFERENCE, targetQualifier: 'UserInfo',    label: 'User Information',   position: 10 },
        { id          : 'RoleInfo',    purpose: #STANDARD, type: #FIELDGROUP_REFERENCE, targetQualifier: 'RoleInfo',    label: 'Role Information',   position: 20 },
        { id          : 'AccessFlags', purpose: #STANDARD, type: #FIELDGROUP_REFERENCE, targetQualifier: 'AccessFlags', label: 'Access Permissions', position: 30 }
      ]
      @UI.hidden      : true
  key SessionId       : abap.char(10);

      // ═══════════════════════════════════════════════════════════════════════════
      // USER IDENTIFICATION
      // ═══════════════════════════════════════════════════════════════════════════
      @UI             : { lineItem: [{ position: 10, importance: #HIGH }], fieldGroup: [{ qualifier: 'UserInfo', position: 10 }] }
      @EndUserText.label: 'User ID'
      UserId          : abap.char(12);

      @UI             : { lineItem: [{ position: 20, importance: #HIGH }], fieldGroup: [{ qualifier: 'UserInfo', position: 20 }] }
      @EndUserText.label: 'Full Name'
      UserFullName    : abap.char(80);

      @UI             : { lineItem: [{ position: 30, importance: #MEDIUM }], fieldGroup: [{ qualifier: 'UserInfo', position: 30 }] }
      @EndUserText.label: 'Email Address'
      Email           : abap.char(241);

      // ═══════════════════════════════════════════════════════════════════════════
      // ROLE INFORMATION
      // ═══════════════════════════════════════════════════════════════════════════
      @UI             : { lineItem: [{ position: 40, importance: #HIGH }], fieldGroup: [{ qualifier: 'RoleInfo', position: 10 }] }
      @EndUserText.label: 'Role ID'
      RoleId          : abap.char(30);

      @UI             : { lineItem: [{ position: 50, importance: #HIGH }], fieldGroup: [{ qualifier: 'RoleInfo', position: 20 }] }
      @EndUserText.label: 'Role Name'
      RoleName        : abap.char(80);

      @UI             : { lineItem: [{ position: 60, importance: #LOW }], fieldGroup: [{ qualifier: 'RoleInfo', position: 30 }] }
      @EndUserText.label: 'Role Description'
      RoleDescription : abap.char(255);

      // ═══════════════════════════════════════════════════════════════════════════
      // ACCESS FLAGS
      // ═══════════════════════════════════════════════════════════════════════════
      @UI             : { lineItem: [{ position: 70, importance: #MEDIUM }], fieldGroup: [{ qualifier: 'AccessFlags', position: 10 }] }
      @EndUserText.label: 'Administrator'
      IsAdmin         : abap_boolean;

      @UI             : { lineItem: [{ position: 80, importance: #MEDIUM }], fieldGroup: [{ qualifier: 'AccessFlags', position: 20 }] }
      @EndUserText.label: 'Head of Accounting'
      IsHeadAcct      : abap_boolean;

      @UI             : { lineItem: [{ position: 90, importance: #LOW }], fieldGroup: [{ qualifier: 'AccessFlags', position: 30 }] }
      @EndUserText.label: 'GL Access'
      HasGLAccess     : abap_boolean;

      @UI             : { lineItem: [{ position: 100, importance: #LOW }], fieldGroup: [{ qualifier: 'AccessFlags', position: 40 }] }
      @EndUserText.label: 'AP Access'
      HasAPAccess     : abap_boolean;

      @UI             : { lineItem: [{ position: 110, importance: #LOW }], fieldGroup: [{ qualifier: 'AccessFlags', position: 50 }] }
      @EndUserText.label: 'AR Access'
      HasARAccess     : abap_boolean;

      // ═══════════════════════════════════════════════════════════════════════════
      // COMPANY CODE ACCESS
      // ═══════════════════════════════════════════════════════════════════════════
      @UI             : { lineItem: [{ position: 120, importance: #MEDIUM }], fieldGroup: [{ qualifier: 'AccessFlags', position: 60 }] }
      @EndUserText.label: 'Company Codes'
      CompanyCodeList : abap.char(1000);
}
