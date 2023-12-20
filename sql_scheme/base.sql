CREATE TABLE users
(
    id              bigint       NOT NULL PRIMARY KEY IDENTITY,
    user_details    bigint       NOT NULL REFERENCES user_details (id),
    login           varchar(16)  NOT NULL,
    hashed_password varchar(128) NOT NULL,
    sex             varchar(6)   NOT NULL CHECK (sex IN ('MALE', 'FEMALE')),
    age             integer      NOT NULL CHECK (age > 0),
    first_name      varchar(101) NOT NULL CHECK (len(first_name) > 0),
    last_name       varchar(101) NOT NULL CHECK (len(last_name) > 0),
    middle_name     varchar(101) NULL,
    location        varchar(50)  NOT NULL CHECK (len(location) > 0),
);
CREATE INDEX user_login_age_first_name_last_name_middle_name ON users (login, age, first_name, last_name, middle_name);

GO
DROP PROCEDURE IF EXISTS registerUser;
CREATE PROCEDURE registerUser @Login varchar,
                              @Password varchar,
                              @Sex varchar,
                              @Age integer,
                              @FirstName varchar,
                              @LastName varchar,
                              @MiddleName varchar,
                              @Location varchar
AS
BEGIN
    -- hashed password
    declare @hashed_password varchar(128) = convert(varchar(1000), HASHBYTES('SHA2_512', @Password), 1)
    if len(@MiddleName) = 0
        SET @MiddleName = NULL;

    INSERT INTO users (login, hashed_password, sex, age, first_name, last_name, middle_name, location)
    values (@Login, @hashed_password, @Sex, @Age, @FirstName, @LastName, @MiddleName, @Location);
    PRINT 'Registered user ' + @Login
END;
GO

CREATE TABLE user_details
(
    id               BIGINT       NOT NULL PRIMARY KEY IDENTITY,
    self_description varchar(max) NOT NULL DEFAULT '',
    preference_id    BIGINT       NOT NULL REFERENCES preferences (id),
)

CREATE TABLE preferences
(
    id        BIGINT  NOT NULL PRIMARY KEY IDENTITY,
    age_start integer NOT NULL,
    age_end   integer NOT NULL,
)

CREATE TABLE hobbies
(
    id             BIGINT        NOT NULL PRIMARY KEY IDENTITY,
    user_detail_id BIGINT        NOT NULL REFERENCES user_details (id),
    name           varchar(64)   NOT NULL,
    description    varchar(3000) NOT NULL,
)

CREATE TABLE likes
(
    id         BIGINT    NOT NULL PRIMARY KEY IDENTITY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    from_whom  bigint    NOT NULL REFERENCES users (id),
    to_whom    bigint    NOT NULL REFERENCES users (id),
    agreed     BIT       NOT NULL DEFAULT 0,
    UNIQUE (from_whom, to_whom)
);

CREATE TRIGGER matched
    ON likes
    AFTER UPDATE AS
    IF (UPDATE(agreed) and agreed = 1)
        BEGIN
            exec placeMatch @from_whom = from_whom, @to_whom = to_whom;
        END;

GO
DROP PROCEDURE IF EXISTS placeLike;
CREATE PROCEDURE placeLike @from_whom BIGINT,
                           @to_whom BIGINT
AS
BEGIN
    INSERT INTO likes (from_whom, to_whom) values (@from_whom, @to_whom);
    PRINT 'Placed like of ' + @from_whom + ' to ' + @to_whom
END;
GO

CREATE TABLE matches
(
    id         bigint     NOT NULL PRIMARY KEY IDENTITY,
    created_at timestamp  NOT NULL                                      DEFAULT CURRENT_TIMESTAMP,
    status     varchar(6) NOT NULL CHECK (status IN ('OPEN', 'CLOSED')) DEFAULT 'OPEN',
    male       bigint     NOT NULL REFERENCES users (id),
    female     bigint     NOT NULL REFERENCES users (id)
);
CREATE INDEX match_match_male_match_female ON matches (male, female);

GO
DROP PROCEDURE IF EXISTS placeMatch;
CREATE PROCEDURE placeMatch @from_whom BIGINT,
                            @to_whom BIGINT
AS
BEGIN
    DECLARE @from_whom_sex varchar(6) = (select sex from users WHERE id = @from_whom);
    DECLARE @to_whom_sex varchar(6) = (select sex from users WHERE id = @to_whom);
    DECLARE @male BIGINT;
    DECLARE @female BIGINT;
    if @from_whom_sex = 'MALE'
        BEGIN
            SET @male = @from_whom_sex;
            SET @female = @to_whom_sex;
        END
    ELSE
        BEGIN
            SET @male = @to_whom_sex;
            SET @female = @from_whom_sex;
        END

    INSERT INTO matches (male, female) VALUES (@male, @female);
    PRINT 'Placed new match ' + @male + ' ' + @female
END;
GO

CREATE TABLE messages
(
    id         integer       NOT NULL PRIMARY KEY IDENTITY,
    from_whom  bigint        NOT NULL REFERENCES users (id),
    to_whom    bigint        NOT NULL REFERENCES users (id),
    match_id   BIGINT        NOT NULL REFERENCES matches (id),
    created_at timestamp     NOT NULL,
    text       varchar(4000) NOT NULL,
    seen       BIT           NOT NULL DEFAULT 0
);
CREATE INDEX message_message_from_message_to ON messages (match_id, from_whom, to_whom);

GO
DROP PROCEDURE IF EXISTS get_recommendation;
CREATE PROCEDURE get_recommendation @user_id BIGINT
AS
BEGIN
    --     DECLARE @users_sex varchar(6);
    DECLARE @users_location varchar(50) = (select location from users WHERE id = @user_id);

    DECLARE @opposite_sex varchar(6);
    if (select sex from users where id = @user_id) = 'MALE'
        SET @opposite_sex = 'FEMALE'
    ELSE
        SET @opposite_sex = 'MALE'

    -- return random user of opposite sex and same location
    select TOP 1 id
    from users
    where sex = @opposite_sex
      and location = @users_location
      and id >= RAND(7) * IDENT_CURRENT(users.id)
    ORDER BY id
END;
GO
