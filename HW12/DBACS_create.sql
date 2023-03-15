CREATE TABLE SetOfPermissionIncludeRoleInfo (
  RoleInfoId         varchar(30) NOT NULL, 
  SetOfPermissionsId int NOT NULL, 
  PRIMARY KEY CLUSTERED (RoleInfoId, 
  SetOfPermissionsId));
CREATE TABLE RoleInfoIncludePermission (
  PermissionId int NOT NULL, 
  RoleInfoId   varchar(30) NOT NULL, 
  PRIMARY KEY CLUSTERED (PermissionId, 
  RoleInfoId));
CREATE TABLE SetOfPermissionIncludePermission (
  PermissionId       int NOT NULL, 
  SetOfPermissionsId int NOT NULL, 
  PRIMARY KEY CLUSTERED (PermissionId, 
  SetOfPermissionsId));
CREATE TABLE PersonBelongToDepartment (
  PersonId     int NOT NULL, 
  DepartmentId int NOT NULL, 
  PRIMARY KEY CLUSTERED (PersonId, 
  DepartmentId));
CREATE TABLE Card (
  Id       int IDENTITY NOT NULL, 
  PersonId int NOT NULL, 
  Number   varchar(30) NOT NULL UNIQUE, 
  IsActive bit DEFAULT 1 NOT NULL, 
  PRIMARY KEY CLUSTERED (Id));
CREATE TABLE Department (
  Id                 int IDENTITY NOT NULL, 
  Name               nvarchar(50) NOT NULL, 
  ParentDepartmentId int NULL, 
  PRIMARY KEY CLUSTERED (Id));
CREATE TABLE FingerPrint (
  Id           int IDENTITY NOT NULL, 
  PersonId     int NOT NULL, 
  FingerNumber int NOT NULL, 
  FingerData   varchar(max) NOT NULL, 
  PRIMARY KEY CLUSTERED (Id), 
  CONSTRAINT UniqueFingerForPerson 
    UNIQUE (PersonId, FingerNumber));
CREATE TABLE NotificationChannel (
  Id                        int IDENTITY NOT NULL, 
  NotificationChannelTypeId varchar(30) NOT NULL, 
  PersonId                  int NOT NULL, 
  IsActive                  bit DEFAULT 1 NOT NULL, 
  ChannelParams             nvarchar(255) NOT NULL, 
  PRIMARY KEY CLUSTERED (Id));
CREATE TABLE NotificationChannelType (
  Id          varchar(30) NOT NULL, 
  Name        nvarchar(30) NOT NULL, 
  Description nvarchar(255) NULL, 
  PRIMARY KEY CLUSTERED (Id));
CREATE TABLE SetOfPermissions (
  Id       int IDENTITY NOT NULL, 
  PersonId int NOT NULL, 
  Name     nvarchar(50) NOT NULL, 
  IsActive bit DEFAULT 1 NOT NULL, 
  PRIMARY KEY CLUSTERED (Id), 
  CONSTRAINT UniqueNameForPerson 
    UNIQUE (PersonId, Name));
CREATE TABLE RoleInfo (
  Id          varchar(30) NOT NULL, 
  Name        nvarchar(30) NOT NULL UNIQUE, 
  Description nvarchar(255) NULL, 
  PRIMARY KEY CLUSTERED (Id));
CREATE TABLE Permission (
  Id               int IDENTITY NOT NULL, 
  IsActive         bit DEFAULT 1 NOT NULL, 
  PermissionTypeId varchar(30) NOT NULL, 
  PRIMARY KEY CLUSTERED (Id));
CREATE TABLE PermissionType (
  Id          varchar(30) NOT NULL, 
  Name        nvarchar(30) NOT NULL UNIQUE, 
  Description nvarchar(255) NULL, 
  PRIMARY KEY CLUSTERED (Id));
CREATE TABLE PermissionToAccessAPerson (
  PersonId     int NOT NULL, 
  PermissionId int NOT NULL UNIQUE, 
  PRIMARY KEY CLUSTERED (PersonId, 
  PermissionId));
CREATE TABLE PermissionToAccessADepartment (
  DepartmentId int NOT NULL, 
  PermissionId int NOT NULL UNIQUE, 
  Recursive    bit DEFAULT 1 NOT NULL, 
  PRIMARY KEY CLUSTERED (DepartmentId, 
  PermissionId));
CREATE TABLE PassEvent (
  Id           bigint IDENTITY NOT NULL, 
  PassTypeId   varchar(30) NOT NULL, 
  PassSourceId int NOT NULL, 
  PassDateTime datetime2(7) DEFAULT GetDate() NOT NULL, 
  PersonId     int NULL, 
  PRIMARY KEY CLUSTERED (Id));
CREATE TABLE PassType (
  Id          varchar(30) NOT NULL, 
  Name        nvarchar(50) NOT NULL UNIQUE, 
  Description nvarchar(255) NULL, 
  PRIMARY KEY CLUSTERED (Id));
CREATE TABLE PassSource (
  Id          int IDENTITY NOT NULL, 
  Name        nvarchar(50) NOT NULL UNIQUE, 
  Description nvarchar(255) NULL, 
  PRIMARY KEY CLUSTERED (Id));
CREATE TABLE UserInfo (
  PersonId     int NOT NULL, 
  UserLogin    varchar(50) NOT NULL, 
  UserPassword varchar(255) NOT NULL, 
  IsActive     bit DEFAULT 1 NOT NULL, 
  PRIMARY KEY CLUSTERED (PersonId));
CREATE TABLE Notification (
  Id                    int IDENTITY NOT NULL, 
  PassEventId           bigint NOT NULL, 
  NotificationStatusId  varchar(30) NOT NULL, 
  NotificationChannelId int NOT NULL, 
  PRIMARY KEY CLUSTERED (Id));
CREATE TABLE NotificationStatus (
  Id          varchar(30) NOT NULL, 
  Name        nvarchar(30) NOT NULL UNIQUE, 
  Description nvarchar(255) NULL, 
  PRIMARY KEY CLUSTERED (Id));
CREATE TABLE Person (
  Id        int IDENTITY NOT NULL, 
  FirstName nvarchar(30) NULL, 
  LastName  nvarchar(30) NOT NULL, 
  Phone     varchar(16) NULL, 
  PRIMARY KEY CLUSTERED (Id));
CREATE INDEX Department_ParentDepartmentId 
  ON Department (ParentDepartmentId);
CREATE INDEX NotificationChannel_PersonId 
  ON NotificationChannel (PersonId);
CREATE INDEX SetOfPermissions_PersonId 
  ON SetOfPermissions (PersonId);
CREATE INDEX PassEvent_PersonId 
  ON PassEvent (PersonId);
CREATE UNIQUE NONCLUSTERED INDEX Person 
  ON Person (Phone) WHERE Phone IS NOT NULL;
ALTER TABLE PermissionToAccessADepartment ADD CONSTRAINT FKPermission781867 FOREIGN KEY (PermissionId) REFERENCES Permission (Id);
ALTER TABLE SetOfPermissionIncludeRoleInfo ADD CONSTRAINT FKSetOfPermi200389 FOREIGN KEY (SetOfPermissionsId) REFERENCES SetOfPermissions (Id);
ALTER TABLE RoleInfoIncludePermission ADD CONSTRAINT FKRoleInfoIn46240 FOREIGN KEY (PermissionId) REFERENCES Permission (Id);
ALTER TABLE SetOfPermissionIncludePermission ADD CONSTRAINT FKSetOfPermi203895 FOREIGN KEY (SetOfPermissionsId) REFERENCES SetOfPermissions (Id);
ALTER TABLE SetOfPermissionIncludePermission ADD CONSTRAINT FKSetOfPermi863100 FOREIGN KEY (PermissionId) REFERENCES Permission (Id);
ALTER TABLE PersonBelongToDepartment ADD CONSTRAINT FKPersonBelo859937 FOREIGN KEY (PersonId) REFERENCES Person (Id);
ALTER TABLE PersonBelongToDepartment ADD CONSTRAINT FKPersonBelo83296 FOREIGN KEY (DepartmentId) REFERENCES Department (Id);
ALTER TABLE Card ADD CONSTRAINT PersonOfCard FOREIGN KEY (PersonId) REFERENCES Person (Id);
ALTER TABLE Department ADD CONSTRAINT ParentDeptId FOREIGN KEY (ParentDepartmentId) REFERENCES Department (Id);
ALTER TABLE FingerPrint ADD CONSTRAINT PersonOfFingerPrint FOREIGN KEY (PersonId) REFERENCES Person (Id);
ALTER TABLE SetOfPermissions ADD CONSTRAINT PersonOfSetOfPermission FOREIGN KEY (PersonId) REFERENCES Person (Id);
ALTER TABLE PermissionToAccessADepartment ADD CONSTRAINT DepartmentOfPermission FOREIGN KEY (DepartmentId) REFERENCES Department (Id);
ALTER TABLE PassEvent ADD CONSTRAINT SourceOfPassEvent FOREIGN KEY (PassSourceId) REFERENCES PassSource (Id);
ALTER TABLE PassEvent ADD CONSTRAINT PersonOfPassEvent FOREIGN KEY (PersonId) REFERENCES Person (Id);
ALTER TABLE NotificationChannel ADD CONSTRAINT PersonOfNotificationChannel FOREIGN KEY (PersonId) REFERENCES Person (Id);
ALTER TABLE SetOfPermissionIncludeRoleInfo ADD CONSTRAINT FKSetOfPermi881879 FOREIGN KEY (RoleInfoId) REFERENCES RoleInfo (Id);
ALTER TABLE RoleInfoIncludePermission ADD CONSTRAINT FKRoleInfoIn376823 FOREIGN KEY (RoleInfoId) REFERENCES RoleInfo (Id);
ALTER TABLE PassEvent ADD CONSTRAINT TypeOfPassEvent FOREIGN KEY (PassTypeId) REFERENCES PassType (Id);
ALTER TABLE Notification ADD CONSTRAINT StatusOfNotification FOREIGN KEY (NotificationStatusId) REFERENCES NotificationStatus (Id);
ALTER TABLE Notification ADD CONSTRAINT PassEventForNotification FOREIGN KEY (PassEventId) REFERENCES PassEvent (Id);
ALTER TABLE UserInfo ADD CONSTRAINT PersonOfUserInfo FOREIGN KEY (PersonId) REFERENCES Person (Id);
ALTER TABLE Permission ADD CONSTRAINT TypeOfPermission FOREIGN KEY (PermissionTypeId) REFERENCES PermissionType (Id);
ALTER TABLE Notification ADD CONSTRAINT ChannelOfNotification FOREIGN KEY (NotificationChannelId) REFERENCES NotificationChannel (Id);
ALTER TABLE NotificationChannel ADD CONSTRAINT TypeOfNotificationChannel FOREIGN KEY (NotificationChannelTypeId) REFERENCES NotificationChannelType (Id);
ALTER TABLE PermissionToAccessAPerson ADD CONSTRAINT FKPermission795882 FOREIGN KEY (PermissionId) REFERENCES Permission (Id);
ALTER TABLE PermissionToAccessAPerson ADD CONSTRAINT PersonOfPermission FOREIGN KEY (PersonId) REFERENCES Person (Id);
SET IDENTITY_INSERT Person ON;
INSERT INTO Person(Id, FirstName, LastName, Phone) VALUES (1, 'Андрей', 'Админородящий', '+79998887766');
INSERT INTO Person(Id, FirstName, LastName, Phone) VALUES (2, 'Анна Ивановна', 'Обучающая', '+79876543219');
INSERT INTO Person(Id, FirstName, LastName, Phone) VALUES (3, 'Александр', 'Админорождённый', null);
INSERT INTO Person(Id, FirstName, LastName, Phone) VALUES (4, 'Евгений Викторович', 'Вахтёров', null);
SET IDENTITY_INSERT Person OFF;
INSERT INTO RoleInfo(Id, Name, Description) VALUES ('Admin', 'Администратор', null);
INSERT INTO RoleInfo(Id, Name, Description) VALUES ('PassSource', 'КПП (вход)', 'Контрольно-пропускной пункт (вход)');
INSERT INTO RoleInfo(Id, Name, Description) VALUES ('Registrar', 'Регистратор (учитель)', null);
INSERT INTO PermissionType(Id, Name, Description) VALUES ('AllPeople', 'Доступ ко всем людям', null);
INSERT INTO PermissionType(Id, Name, Description) VALUES ('AllDepts', 'Доступ ко всем отделам', null);
INSERT INTO PermissionType(Id, Name, Description) VALUES ('Person', 'Доступ к человеку Х', null);
INSERT INTO PermissionType(Id, Name, Description) VALUES ('Dept', 'Доступ к отделу Х', null);
INSERT INTO PermissionType(Id, Name, Description) VALUES ('AddPeople', 'Внесение новых людей', null);
INSERT INTO PermissionType(Id, Name, Description) VALUES ('AddDepts', 'Внесение новых отделов', null);
INSERT INTO PermissionType(Id, Name, Description) VALUES ('GrantPerson', 'Предоставление доступа', 'Предоставление человеку доступа к другому человеку, к которому у самого есть доступ через отдел');
SET IDENTITY_INSERT Department ON;
INSERT INTO Department(Id, Name, ParentDepartmentId) VALUES (1, 'Персонал школы', null);
INSERT INTO Department(Id, Name, ParentDepartmentId) VALUES (2, 'Учителя', 1);
INSERT INTO Department(Id, Name, ParentDepartmentId) VALUES (3, 'Ученики', null);
INSERT INTO Department(Id, Name, ParentDepartmentId) VALUES (4, 'Родители', null);
INSERT INTO Department(Id, Name, ParentDepartmentId) VALUES (5, '7 классы', 3);
INSERT INTO Department(Id, Name, ParentDepartmentId) VALUES (6, '7Б', 5);
INSERT INTO Department(Id, Name, ParentDepartmentId) VALUES (7, 'Кружок рисования', 3);
SET IDENTITY_INSERT Department OFF;
INSERT INTO PersonBelongToDepartment(PersonId, DepartmentId) VALUES (1, 1);
INSERT INTO PersonBelongToDepartment(PersonId, DepartmentId) VALUES (1, 4);
INSERT INTO PersonBelongToDepartment(PersonId, DepartmentId) VALUES (2, 2);
INSERT INTO PersonBelongToDepartment(PersonId, DepartmentId) VALUES (3, 6);
INSERT INTO PersonBelongToDepartment(PersonId, DepartmentId) VALUES (3, 7);
INSERT INTO NotificationChannelType(Id, Name, Description) VALUES ('SMS', 'СМС', 'Оповещение через СМС-сообщение');
INSERT INTO NotificationChannelType(Id, Name, Description) VALUES ('Push', 'Push', 'Оповещение через Push-сообщение');
INSERT INTO NotificationChannelType(Id, Name, Description) VALUES ('EMail', 'EMail', 'Оповещение через сообщение на электронную почту');
INSERT INTO NotificationChannelType(Id, Name, Description) VALUES ('Telegram', 'Telegram', 'Оповещение через сообщение в Telegram');
SET IDENTITY_INSERT NotificationChannel ON;
INSERT INTO NotificationChannel(Id, NotificationChannelTypeId, PersonId, IsActive, ChannelParams) VALUES (1, 'EMail', 1, 1, 'Parent@mail.ru');
SET IDENTITY_INSERT NotificationChannel OFF;
SET IDENTITY_INSERT SetOfPermissions ON;
INSERT INTO SetOfPermissions(Id, PersonId, Name, IsActive) VALUES (1, 1, 'Администратор', 1);
INSERT INTO SetOfPermissions(Id, PersonId, Name, IsActive) VALUES (2, 1, 'Родитель', 1);
INSERT INTO SetOfPermissions(Id, PersonId, Name, IsActive) VALUES (3, 2, 'Учитель', 1);
INSERT INTO SetOfPermissions(Id, PersonId, Name, IsActive) VALUES (4, 4, 'Надзиратель', 1);
SET IDENTITY_INSERT SetOfPermissions OFF;
SET IDENTITY_INSERT Permission ON;
INSERT INTO Permission(Id, IsActive, PermissionTypeId) VALUES (1, 1, 'AllPeople');
INSERT INTO Permission(Id, IsActive, PermissionTypeId) VALUES (2, 1, 'AllDepts');
INSERT INTO Permission(Id, IsActive, PermissionTypeId) VALUES (3, 1, 'AddPeople');
INSERT INTO Permission(Id, IsActive, PermissionTypeId) VALUES (4, 1, 'AddDepts');
INSERT INTO Permission(Id, IsActive, PermissionTypeId) VALUES (5, 1, 'GrantPerson');
INSERT INTO Permission(Id, IsActive, PermissionTypeId) VALUES (6, 1, 'Person');
INSERT INTO Permission(Id, IsActive, PermissionTypeId) VALUES (7, 1, 'Dept');
SET IDENTITY_INSERT Permission OFF;
INSERT INTO SetOfPermissionIncludePermission(PermissionId, SetOfPermissionsId) VALUES (6, 2);
INSERT INTO SetOfPermissionIncludePermission(PermissionId, SetOfPermissionsId) VALUES (7, 3);
INSERT INTO RoleInfoIncludePermission(PermissionId, RoleInfoId) VALUES (1, 'Admin');
INSERT INTO RoleInfoIncludePermission(PermissionId, RoleInfoId) VALUES (2, 'Admin');
INSERT INTO RoleInfoIncludePermission(PermissionId, RoleInfoId) VALUES (3, 'Admin');
INSERT INTO RoleInfoIncludePermission(PermissionId, RoleInfoId) VALUES (4, 'Admin');
INSERT INTO RoleInfoIncludePermission(PermissionId, RoleInfoId) VALUES (5, 'Admin');
INSERT INTO RoleInfoIncludePermission(PermissionId, RoleInfoId) VALUES (1, 'PassSource');
INSERT INTO RoleInfoIncludePermission(PermissionId, RoleInfoId) VALUES (2, 'PassSource');
INSERT INTO RoleInfoIncludePermission(PermissionId, RoleInfoId) VALUES (3, 'Registrar');
INSERT INTO RoleInfoIncludePermission(PermissionId, RoleInfoId) VALUES (5, 'Registrar');
INSERT INTO PermissionToAccessAPerson(PersonId, PermissionId) VALUES (3, 6);
INSERT INTO PermissionToAccessADepartment(DepartmentId, PermissionId, Recursive) VALUES (6, 7, 1);
INSERT INTO PassType(Id, Name, Description) VALUES ('SuccIn', 'Успешный вход', null);
INSERT INTO PassType(Id, Name, Description) VALUES ('SuccOut', 'Успешный выход', null);
INSERT INTO PassType(Id, Name, Description) VALUES ('AbortIn', 'Незавершённый вход', null);
INSERT INTO PassType(Id, Name, Description) VALUES ('AbortOut', 'Незавершённый выход', null);
INSERT INTO PassType(Id, Name, Description) VALUES ('UnauthIn', 'Несанкционированная попытка входа', null);
INSERT INTO PassType(Id, Name, Description) VALUES ('UnauthOut', 'Несанкционированная попытка выхода', null);
SET IDENTITY_INSERT PassSource ON;
INSERT INTO PassSource(Id, Name, Description) VALUES (1, 'Ручной ввод', 'События создаются вручную');
INSERT INTO PassSource(Id, Name, Description) VALUES (2, 'Главный вход', 'Главный вход');
SET IDENTITY_INSERT PassSource OFF;
SET IDENTITY_INSERT PassEvent ON;
INSERT INTO PassEvent(Id, PassTypeId, PassSourceId, PassDateTime, PersonId) VALUES (1, 'SuccIn', 2, GetDate(), 3);
SET IDENTITY_INSERT PassEvent OFF;
INSERT INTO UserInfo(PersonId, UserLogin, UserPassword, IsActive) VALUES (1, 'Admin', '12346', 1);
INSERT INTO UserInfo(PersonId, UserLogin, UserPassword, IsActive) VALUES (2, 'BestTeacher', 'qwerty', 1);
INSERT INTO UserInfo(PersonId, UserLogin, UserPassword, IsActive) VALUES (4, 'Gangsta', 'XXX', 1);
INSERT INTO NotificationStatus(Id, Name, Description) VALUES ('Waiting', 'Ожидает отправки', 'Оповещение ожидает отправки');
INSERT INTO NotificationStatus(Id, Name, Description) VALUES ('Sent', 'Отправлено', 'Оповещение отправлено');
INSERT INTO NotificationStatus(Id, Name, Description) VALUES ('Error', 'Ошибка', 'При отправке оповещения произошла ошибка');
INSERT INTO SetOfPermissionIncludeRoleInfo(RoleInfoId, SetOfPermissionsId) VALUES ('Admin', 1);
INSERT INTO SetOfPermissionIncludeRoleInfo(RoleInfoId, SetOfPermissionsId) VALUES ('Registrar', 3);
INSERT INTO SetOfPermissionIncludeRoleInfo(RoleInfoId, SetOfPermissionsId) VALUES ('PassSource', 4);
