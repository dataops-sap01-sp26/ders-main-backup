@EndUserText.label: 'Current User Information'
define abstract entity ZA_DRS_CURRENT_USER
{
  UserId          : abap.char(12);           // SY-UNAME
  UserFullName    : abap.char(80);           // Full name from USER_ADDRP
  Email           : abap.char(241);          // Email from ADR6
  RoleId          : abap.char(30);           // PFCG Role name (AGR_NAME)
  RoleName        : abap.char(80);           // Role description/display name
  RoleDescription : abap.char(255);          // Extended role description
  IsAdmin         : abap_boolean;            // Has ZDRS_ADMIN role
  IsHeadAcct      : abap_boolean;            // Has ZDRS_HEAD_ACCT role
  HasGLAccess     : abap_boolean;            // Has ZDRS_FI_GL_STAFF role
  HasAPAccess     : abap_boolean;            // Has ZDRS_FI_AP_STAFF role
  HasARAccess     : abap_boolean;            // Has ZDRS_FI_AR_STAFF role
  CompanyCodeList : abap.char(1000);         // Comma-separated list of accessible company codes
}
