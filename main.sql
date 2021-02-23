-- 1. Écrire les requêtes de création des tables « Etudiant » et « Séance ».
create table Etudiant
(
    CIN    int primary key,
    nom    varchar2(30) not null,
    prenom varchar2(30) not null,
    age    int          not null
);

create table Enseignant
(
    id     varchar2(50) primary key,
    nom    varchar2(30) not null,
    prenom varchar2(30) not null
);

create table Cours
(
    code          varchar2(20) primary key,
    intitule      varchar2(50) not null,
    responsable   varchar2(20) not null,
    nombre_seance int          not null,
    constraint fk_enseignant foreign key (responsable) references Enseignant (id)
);

create table Seance
(
    cours      varchar2(20) not null,
    numero     int          not null,
    type       varchar2(10) not null,
    "date"     date         not null,
    salle      varchar2(20) not null,
    heureDebut smallint     not null,
    heureFin   smallint     not null,
    enseignant varchar2(50) not null,
    constraint fk_cours FOREIGN KEY (cours) references Cours (code),
    constraint fk_enseignant2 FOREIGN KEY (enseignant) references Enseignant (id),
    constraint pk_seance PRIMARY KEY (cours, numero),
    constraint type_enum check ( type in ('CM', 'TP', 'TD') ),
    constraint hours_logic check ( (heureFin between 0 and 23) and (heureDebut between 0 and heureFin - 1)
        )
);

create table inscription
(
    etudiant int          not null,
    cours    varchar2(20) not null,
    constraint fk_etudiant_inscription foreign key (etudiant) references Etudiant (cin),
    constraint fk_cours_inscription foreign key (cours) references COURS (code),
    constraint pk_inscription primary key (etudiant, cours)
);

-- 2. Inscrivez
-- l’étudiant (’l0372’,’Mohamed’,’Salah’,20)
-- au cours (’LOG015’,’Logique’,’jh1908’).

insert into Etudiant(cin, nom, prenom, age)
values (10372, 'Mohamed', 'Salah', 20);

insert into Enseignant (id, nom, prenom)
values ('jh1908', 'robena', 'narjes');

insert into COURS (code, intitule, responsable, nombre_seance)
values ('LOG015', 'Logique', 'jh1908', 10);

-- 3. Cherchez le nom et le prénom de tous les étudiants inscrits au cours de Probabilités.

select Et.nom, Et.prenom
from Etudiant Et
         inner join inscription I on Et.CIN = I.etudiant
         inner join COURS C on C.code = I.COURS
where C.intitule = 'Probabilités';

-- 4. Déterminer le nombre d’enseignants intervenant dans le cours de Modélisation.

select count(E.id) "Nombre"
from Enseignant E
         inner join COURS C on E.id = C.responsable
where C.intitule = 'Modélisation';

-- 5. Pour chaque enseignant, indiquez le nombre de cours dans lesquels il intervient
-- (restreignez les réponses à l’ensemble des enseignants qui interviennent dans au moins
-- deux cours).

select E.prenom, E.id, count(Distinct (S.cours)) "count"
from Enseignant E
         inner join Seance S on S.enseignant = E.id
group by (E.id, E.prenom)
having count(distinct (S.cours)) >= 2;


-- 1.Ajoutez un cours magistral de Logique le 14 décembre avec Foulen ben foulen en salle
-- S250 de 14h à 18h.

-- 2 Listez les étudiants inscrits à aucun cours.

select E.cin
from Etudiant E
where not exists(
        select C.code
        from COURS C
                 inner join inscription I on i.COURS = C.code
        where E.CIN = i.etudiant
    );

-- VIEWS
-- Définissez une vue nommée EdtEuler fournissant pour chaque séance assurée par M. Euler l’intitulé du cours, la date
-- , l’heure de début, la durée, la salle et le nombre
-- d’étudiants devant assister à la séance.

create view EdtEuler as
select C.intitule,
       S."date",
       S.heureDebut,
       (S.heureFin - S.heureDebut) "dure",
       S.salle,
       COUNT(I.etudiant)           NbrEtudiant
from Enseignant E
         inner join Seance S on E.id = S.enseignant
         inner join Cours C on S.cours = C.code
         inner join INSCRIPTION I on I.COURS = C.code
where E.nom = 'Euler'
group by (S.cours, S.numero);

-- Imaginez une vue matérialisant l’emploi du temps d’une salle (par exemple la salle N267).

create view EmpoloiN267 as
select C.intitule, S.cours, S.numero, S."date", S.heureDebut, S.HEUREFIN
from Cours C
         inner join Seance S on C.code = S.cours
where s.salle = 'N267'
order by S."date", s.heureDebut;

-- La salle N267 a une capacité maximale de 20 étudiants. Déterminez, à l’aide de la vue
-- précédemment créée, les séances pour lesquelles il est nécessaire de changer de salle.

create view changerSaleN267 as
select Emp.cours, Emp.numero
from EmpoloiN267 Emp
         inner join inscription i on Emp.cours = i.cours
         inner join Etudiant E on E.CIN = i.etudiant
group by (E.CIN, Emp.cours, Emp.numero)
having count(E.CIN) > 20
