CREATE TABLE Card (Id int IDENTITY NOT NULL, PersonId int NOT NULL, Number varchar(30) NOT NULL UNIQUE, IsActive bit DEFAULT 1 NOT NULL, PRIMARY KEY CLUSTERED (Id));
CREATE TABLE Department (Id int IDENTITY NOT NULL, Name nvarchar(50) NOT NULL, ParentDepartmentId int NULL, PRIMARY KEY CLUSTERED (Id));
CREATE TABLE FingerPrint (Id int IDENTITY NOT NULL, PersonId int NOT NULL, FingerNumber int NOT NULL, FingerData varchar(4000) NOT NULL, PRIMARY KEY CLUSTERED (Id), CONSTRAINT UniqueFingerForPerson UNIQUE (PersonId, FingerNumber));
CREATE TABLE NotificationChannel (Id int IDENTITY NOT NULL, PersonId int NOT NULL, NotificationChannelTypeId varchar(30) NOT NULL, IsActive bit DEFAULT 1 NOT NULL, ChannelParams nvarchar(1000) NOT NULL, PRIMARY KEY CLUSTERED (Id));
CREATE TABLE NotificationChannelType (Id varchar(30) NOT NULL, Name nvarchar(30) NOT NULL UNIQUE, Description nvarchar(255) NULL, PRIMARY KEY CLUSTERED (Id));
CREATE TABLE PassEvent (Id bigint IDENTITY NOT NULL, PassTypeId varchar(30) NOT NULL, PassSourceId int NOT NULL, PassDateTime datetime2(7) DEFAULT GetDate() NOT NULL, PersonId int NULL, PRIMARY KEY CLUSTERED (Id));
CREATE TABLE PassSource (Id int IDENTITY NOT NULL, Name nvarchar(30) NOT NULL UNIQUE, Description nvarchar(255) NULL, PRIMARY KEY CLUSTERED (Id));
CREATE TABLE PassType (Id varchar(30) NOT NULL, Name nvarchar(50) NOT NULL UNIQUE, Description nvarchar(255) NULL, PRIMARY KEY CLUSTERED (Id));
CREATE TABLE Permission (Id int IDENTITY NOT NULL, PermissionTypeId varchar(30) NOT NULL, IsActive bit DEFAULT 1 NOT NULL, PRIMARY KEY CLUSTERED (Id));

-- Создавая кластерный индекс по отделу, мы быстро найдём разрешения, имеющие доступ к отделу.
CREATE TABLE PermissionToAccessADepartment (DepartmentId int NOT NULL, PermissionId int NOT NULL UNIQUE, Recursive bit DEFAULT 1 NOT NULL, PRIMARY KEY CLUSTERED (DepartmentId, PermissionId)); 

 -- Создавая кластерный индекс по человеку, мы быстро найдём разрешения, имеющие доступ к человеку.
CREATE TABLE PermissionToAccessAPerson (PersonId int NOT NULL, PermissionId int NOT NULL UNIQUE, PRIMARY KEY CLUSTERED (PersonId, PermissionId));
CREATE TABLE PermissionType (Id varchar(30) NOT NULL, Name nvarchar(30) NOT NULL UNIQUE, Description nvarchar(255) NULL, PRIMARY KEY CLUSTERED (Id));
CREATE TABLE Person (Id int IDENTITY NOT NULL, FirstName nvarchar(30) NOT NULL, LastName nvarchar(30) NOT NULL, Phone varchar(16) NULL, PRIMARY KEY CLUSTERED (Id));
CREATE TABLE PersonBelongToDepartment (PersonId int NOT NULL, DepartmentId int NOT NULL, PRIMARY KEY (PersonId, DepartmentId));
CREATE TABLE RoleInfo (Id varchar(30) NOT NULL, Name nvarchar(30) NOT NULL UNIQUE, Description nvarchar(255) NULL, PRIMARY KEY CLUSTERED (Id));
CREATE TABLE RoleInfoIncludePermission (PermissionId int NOT NULL, RoleInfoId varchar(30) NOT NULL, PRIMARY KEY (PermissionId, RoleInfoId));
CREATE TABLE SetOfPermissionIncludePermission (PermissionId int NOT NULL, SetOfPermissionsId int NOT NULL, PRIMARY KEY (PermissionId, SetOfPermissionsId));
CREATE TABLE SetOfPermissionIncludeRoleInfo (SetOfPermissionsId int NOT NULL, RoleInfoId varchar(30) NOT NULL, PRIMARY KEY (SetOfPermissionsId, RoleInfoId));
CREATE TABLE SetOfPermissions (Id int IDENTITY NOT NULL, PersonId int NOT NULL, Name nvarchar(50) NOT NULL, IsActive bit DEFAULT 1 NOT NULL, PRIMARY KEY CLUSTERED (Id), CONSTRAINT UniqueNameForPerson UNIQUE (PersonId, Name));
CREATE TABLE UserInfo (PersonId int NOT NULL, UserLogin varchar(255) NOT NULL, UserPassword varchar(255) NOT NULL, IsActive bit DEFAULT 1 NOT NULL, PRIMARY KEY CLUSTERED (PersonId));

-- Нужен для построения иерархии отделов через CTE
CREATE INDEX Department_ParentDepartmentId ON Department (ParentDepartmentId);
-- Нужен для поиска каналов оповещения для человека 
CREATE INDEX NotificationChannel_PersonId ON NotificationChannel (PersonId);
-- Нужен для выборки на текущий день, неделю, месяц
CREATE INDEX PassEvent_PassDateTime ON PassEvent (PassDateTime);
-- Нужен для выборки посещений для определённого человека
CREATE INDEX PassEvent_PersonId ON PassEvent (PersonId);
-- Нужен, чтобы исключить повтор телефонов, если он задан
CREATE UNIQUE NONCLUSTERED INDEX Person ON Person (Phone) WHERE Phone IS NOT NULL;
-- Нужен для поиска человека по фамилии
CREATE INDEX Person_LastName ON Person (LastName);
-- Нужен для поиска разрешений для человека
CREATE INDEX SetOfPermissions_PersonId ON SetOfPermissions (PersonId);
-- Логин не должен повторяться
CREATE UNIQUE INDEX UserInfo_UserLogin ON UserInfo (UserLogin);

ALTER TABLE PermissionToAccessAPerson ADD CONSTRAINT FKPermission795882 FOREIGN KEY (PermissionId) REFERENCES Permission (Id);
ALTER TABLE PermissionToAccessADepartment ADD CONSTRAINT FKPermission781867 FOREIGN KEY (PermissionId) REFERENCES Permission (Id);
ALTER TABLE SetOfPermissionIncludeRoleInfo ADD CONSTRAINT FKSetOfPermi200389 FOREIGN KEY (SetOfPermissionsId) REFERENCES SetOfPermissions (Id);
ALTER TABLE RoleInfoIncludePermission ADD CONSTRAINT FKRoleInfoIn46240 FOREIGN KEY (PermissionId) REFERENCES Permission (Id);
ALTER TABLE SetOfPermissionIncludePermission ADD CONSTRAINT FKSetOfPermi203895 FOREIGN KEY (SetOfPermissionsId) REFERENCES SetOfPermissions (Id);
ALTER TABLE SetOfPermissionIncludePermission ADD CONSTRAINT FKSetOfPermi863100 FOREIGN KEY (PermissionId) REFERENCES Permission (Id);
ALTER TABLE PersonBelongToDepartment ADD CONSTRAINT FKPersonBelo859937 FOREIGN KEY (PersonId) REFERENCES Person (Id);
ALTER TABLE PersonBelongToDepartment ADD CONSTRAINT FKPersonBelo83296 FOREIGN KEY (DepartmentId) REFERENCES Department (Id);
ALTER TABLE SetOfPermissionIncludeRoleInfo ADD CONSTRAINT FKSetOfPermi881879 FOREIGN KEY (RoleInfoId) REFERENCES RoleInfo (Id);
ALTER TABLE RoleInfoIncludePermission ADD CONSTRAINT FKRoleInfoIn376823 FOREIGN KEY (RoleInfoId) REFERENCES RoleInfo (Id);
ALTER TABLE PermissionToAccessADepartment ADD CONSTRAINT DepartmentOfPermission FOREIGN KEY (DepartmentId) REFERENCES Department (Id);
ALTER TABLE Department ADD CONSTRAINT ParentDeptId FOREIGN KEY (ParentDepartmentId) REFERENCES Department (Id);
ALTER TABLE Card ADD CONSTRAINT PersonOfCard FOREIGN KEY (PersonId) REFERENCES Person (Id);
ALTER TABLE NotificationChannel ADD CONSTRAINT PersonOfChannel FOREIGN KEY (PersonId) REFERENCES Person (Id);
ALTER TABLE FingerPrint ADD CONSTRAINT PersonOfFingerPrint FOREIGN KEY (PersonId) REFERENCES Person (Id);
ALTER TABLE PassEvent ADD CONSTRAINT PersonOfPassEvent FOREIGN KEY (PersonId) REFERENCES Person (Id);
ALTER TABLE PermissionToAccessAPerson ADD CONSTRAINT PersonOfPernission FOREIGN KEY (PersonId) REFERENCES Person (Id);
ALTER TABLE SetOfPermissions ADD CONSTRAINT PersonOfSetOfPermission FOREIGN KEY (PersonId) REFERENCES Person (Id);
ALTER TABLE UserInfo ADD CONSTRAINT PersonOfUserInfo FOREIGN KEY (PersonId) REFERENCES Person (Id);
ALTER TABLE PassEvent ADD CONSTRAINT SourceOfPassEvent FOREIGN KEY (PassSourceId) REFERENCES PassSource (Id);
ALTER TABLE NotificationChannel ADD CONSTRAINT TypeOfNotificationChannel FOREIGN KEY (NotificationChannelTypeId) REFERENCES NotificationChannelType (Id);
ALTER TABLE PassEvent ADD CONSTRAINT TypeOfPassEvent FOREIGN KEY (PassTypeId) REFERENCES PassType (Id);
ALTER TABLE Permission ADD CONSTRAINT TypeOfPermission FOREIGN KEY (PermissionTypeId) REFERENCES PermissionType (Id);

INSERT INTO NotificationChannelType(Id, Name, Description) VALUES ('SMS', N'СМС', N'Оповещение через СМС-сообщение')
, ('Push', N'Push', N'Оповещение через Push-сообщение')
, ('EMail', N'EMail', N'Оповещение через сообщение на электронную почту')
, ('Telegram', N'Telegram', N'Оповещение через сообщение в Telegram');

INSERT INTO PassType(Id, Name) VALUES ('SuccIn', N'Успешный вход')
, ('SuccOut', N'Успешный выход')
, ('AbortIn', N'Незавершённый вход')
, ('AbortOut', N'Незавершённый выход')
, ('UnauthIn', N'Несанкционированная попытка входа')
, ('UnauthOut', N'Несанкционированная попытка выхода')
;

INSERT INTO PermissionType(Id, Name, Description) VALUES ('AllPeople', N'Доступ ко всем людям', NULL)
, ('AllDepts', N'Доступ ко всем отделам', NULL)
, ('Person', N'Доступ к человеку Х', NULL)
, ('Dept', N'Доступ к отделу Х', NULL)
, ('AddPeople', N'Внесение новых людей', NULL)
, ('AddDepts', N'Создание новых отделов', NULL)
, ('GrantPerson', N'Предоставление доступа', N'Предоставление человеку доступа к другому человеку, к которому у самого есть доступ через отдел')
;

INSERT INTO Permission(PermissionTypeId) VALUES ('AllPeople')
, ('AllDepts')
, ('AddPeople')
, ('AddDepts')
, ('GrantPerson')
;

INSERT INTO RoleInfo(Id, Name, Description) VALUES ('Admin', N'Администратор', NULL)
, ('PassSource', N'КПП (вход)', N'Контрольно-пропускной пункт (вход)')
, ('Registrar', N'Регистратор (учитель)', NULL)
;

INSERT INTO RoleInfoIncludePermission (RoleInfoId
, PermissionId
)
SELECT 'Admin' RoleInfoId
, Id 
FROM Permission 
WHERE PermissionTypeId IN ('AllPeople'
, 'AllDepts'
, 'AddPeople'
, 'AddDepts'
, 'GrantPerson'
);

INSERT INTO RoleInfoIncludePermission (RoleInfoId
, PermissionId
)
SELECT 'PassSource' RoleInfoId
, Id 
FROM Permission 
WHERE PermissionTypeId IN ('AllPeople'
, 'AllDepts'
);

INSERT INTO RoleInfoIncludePermission (RoleInfoId
, PermissionId
)
SELECT 'Registrar' RoleInfoId
, Id 
FROM Permission 
WHERE PermissionTypeId IN ('AddPeople'
, 'GrantPerson'
);