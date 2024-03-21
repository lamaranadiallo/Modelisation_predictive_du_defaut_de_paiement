/*=====================================================================================================================================================*/
/* 																																					   */
/* 													PROJET DE MODELISATION DATAMINING AVEC SAS														   */
/* 																																					   */
/*=====================================================================================================================================================*/


libname Projet 'E:\PROJET\Datasets'; /* CREATION DE LA LIBRAIRIE DU PROJET */
options compress = yes; /* "options compress=yes" permet de compresser des tables SAS qu'il faut mettre juste après la library */

/* CREATION D'UNE COPIE DE LA TABLE DE DONNEES DU PROJET */
data projet.Table_projet;
	set projet.Table_groupe1;
run;

/*========================================================================================================================================= */
/*									 			EXPLORATION DE LA TABLE DE DONNEES 															*/
/*========================================================================================================================================= */
ods pdf file = 'E:\PROJET\PDF\contents_tab_projet.pdf'; /* création d'un fichier pdf contenant les resultats de "proc contents" */
	proc contents data = projet.table_projet;
	run;
ods pdf close;

/* RENOMMER LA VARIABLE A MODELISER "var_modeliser" en "defaut_paiement"*/
DATA projet.table_projet;
	set projet.table_projet;
	rename var_modeliser = Defaut_Paiement;
run;

/*=======================================================================================================================================================*/
/*												EXPLORATION DES DONNEES ET TRAITEMENT DES DONNEES MANQUANTES											 */
/*=======================================================================================================================================================*/

									/************************************************************************/
									/*  		   EXPLORATION DE LA VARIABLE A MODELISER   				*/
									/***********************************************************************/
ods pdf file = 'E:\PROJET\PDF\exploration_var_modeliser.pdf'; /* création d'un fichier pdf pour l'exploration de la variable à modeliser */
proc freq data = projet.table_projet;
	table defaut_paiement;
run;
ods pdf close;

									/*************************************************************************/
									/*  		   EXPLORATION DES PREDICTEURS QUALITATIFS  				 */
									/*************************************************************************/

%macro exploration_qualitatif(variable = ); /* Création d'une macro permettant de faire le croisement avec la variable a modeliser (defaut_paiement)*/
	proc freq data = projet.table_projet;
		tables &variable. * defaut_paiement;
	run;
%mend;


/* Appel de la MACRO pour le predicteur "Statut_compte" */
%exploration_qualitatif(variable = Statut_compte);


/* Appel de la MACRO pour le predicteur "Statut_matrimoniale_client" */
%exploration_qualitatif(variable = Statut_matrimonial_client);
/*les resultats obtenues de l'exploration de cette variable montre 15350 données manquantes. */

/* codage des données manquantes du predicteur "STATUT_MATRIMONIAL_CLIENT" */
data projet.table_projet;
	set projet.table_projet;
	if Statut_matrimonial_client = " " then Statut_matrimonial_client = '9';
run;
/* il faut donc refaire l'appel de la MACRO*/
/* Appel de la MACRO pour le predicteur "Statut_matrimoniale_client" */
%exploration_qualitatif(variable = Statut_matrimonial_client);


/* Appel de la MACRO pour le predicteur "type_residence_client" */
%exploration_qualitatif(variable = type_residence_client); /*les resultats obtenues de l'exploration de cette variable montre 14414 données manquantes. */

/* CODAGE des données manquantes de la variable "type_residence_client" */
data projet.table_projet;
	set projet.table_projet;
	if type_residence_client = " " then type_residence_client = 'M';
run;
/* il faut donc refaire l'appel de la MACRO*/
/* Appel de la MACRO pour le predicteur "type_residence_client" */
%exploration_qualitatif(variable = type_residence_client);


									/************************************************************************/
									/*  		   EXPLORATION DES PREDICTEURS QUANTITATIFS  			    */
									/************************************************************************/

/** RECHERCHE DES DONNEES MANQUANTES DES PREDICTEURS QUANTITATIFS **/

proc means data = projet.table_projet nmiss;
	var; /* SAS prend toutes les variables quantitatives*/
run; 


/*==================================================================================================================================================*/
/*											 					ECHANTILLONAGE 																		*/ 
/*==================================================================================================================================================*/
  
/* tri de la table du projet selon la variable à modeliser "defaut_paiement" */
proc sort data = projet.table_projet;
	by defaut_paiement;
run;
 

/* Séparation Aleatoire de la table en deux (2) echantillons: 70% pour l'echantillon d'apprentissage et 30% pour la validation  */
proc surveyselect data = projet.table_projet
	method = srs
	out = projet.table_projet_echantillon
	samprate = 0.70
	seed = 1997 
	outall noprint;
run;

/* Croisement de chaque echantillon avec la variable à modeliser */
proc freq data = projet.table_projet_echantillon;
	tables selected * defaut_paiement;
run;


/* verification si les deux echantillons proviennent de la meme population*/
ods pdf file = 'E:\PROJET\PDF\test_kolmogorov.pdf';
proc npar1way data = projet.table_projet_echantillon;
	class selected;
	var score_actuel_compte;
run;
ods pdf close;


/*SAUVEGARDE DES DEUX ECHANTILLONS */
data  projet.table_apprentissage(drop = selected) projet.table_validation(drop = selected);
set projet.table_projet_echantillon;
	if selected = 1 then
		output projet.table_apprentissage;
	else output projet.table_validation;
run;

/*==============================================================================================================================================*/
/* 																SELECTION DE VARIABLES 															*/
/*==============================================================================================================================================*/

ods pdf file = 'E:\PROJET\PDF\selection_variable.pdf'; /* Enregistrement du resultat de la selection des variables dans un fichier PDF*/
proc stepdisc data = projet.table_apprentissage slentry = 0.90 slstay = 0.80 short;
	class defaut_paiement;
	var Anciennete_compte--Solde_courant_autres_pct_limite Age_client;
run;
ods pdf close;

/*Analyse de la corrélation des variables de la famille "retard" */
ods pdf file = 'E:\PROJET\PDF\correl_variable_retard.pdf';
proc corr data = projet.table_apprentissage;
	var retard_courant retard_min_6derniers_mois retard_max_6derniers_mois;
run; 
ods pdf close; /*les variables retard_min et retard_max sont parfaitement correlées, dans la suite nous prvilègions la variable "retard_max_6derniers_mois" */

/*Analyse de la corrélation des variables de la famille "utilisation" */
ods pdf file = 'E:\PROJET\PDF\correl_variable_utilisation.pdf';
proc corr data = projet.table_apprentissage;
	var  pct_utilisation_courant pct_utilisation_max_1to6m;
run;/* l'analyse de correlation des variables de la famille "utilisation" ne detecte aucune problématique, donc aucune variable de la famille n'est supprimée*/
ods pdf close;

/*Analyse de la corrélation des variables de la famille "Solde" */
ods pdf file = 'E:\PROJET\PDF\correl_variable_solde.pdf';
proc corr data = projet.table_apprentissage;
	var   solde_courant_autres_pct_limite solde_courant solde_courant_pct_max1to6m solde_courant_autres;
run; /*l'analyse de correlation des variables de la famille "solde" ne detecte aucune problématique, donc aucune variable de la famille n'est supprimée*/
ods pdf close;

/*Analyse de la corrélation des variables de la famille "Achat" */
ods pdf file = 'E:\PROJET\PDF\correl_variable_achat.pdf';
proc corr data = projet.table_apprentissage;
	var  achats_courant achats_courant_pct_moy_1to6m;
run; /*l'analyse de correlation des variables de la famille "achat" ne detecte aucune problématique, donc aucune variable de la famille n'est supprimée*/
ods pdf close;

/*==================================================================================================================================================*/
/*													  DISCRETISATION (categorisation des predicteurs)  												*/
/*==================================================================================================================================================*/

									/************************************************************************/
									/*  		   DISCRETISATION DES PREDICTEURS QUALITATIFS  			    */
									/************************************************************************/

/* CROISEMENT entre statut_compte * defaut_paiement */
proc freq data = projet.table_apprentissage;
	tables statut_compte * defaut_paiement;
run;

/* CODAGE DE LA VARIABLE "statut_compte"*/
data projet.table_apprentissage; 
	set projet.table_apprentissage; 
	if statut_compte = 'O' then statut_compte_C = '1';
	else statut_compte_C = '2';
run;

/* croisement de la nouvelle variable "statut_compte_C" avec "defaut_paiement" */
proc freq data = projet.table_apprentissage;
	tables  statut_compte_C * defaut_paiement;
run;


/* CROISEMENT entre statut_matrimonial_client * defaut_paiement */
proc freq data = projet.table_apprentissage;
	tables statut_matrimonial_client * defaut_paiement;
run;

/* regroupement des modalites de la variable "statut_matrimonial_client": (0,1,5) ; 2 ; 3; 4 et (9) */
data projet.table_apprentissage;
	set projet.table_apprentissage;
	if statut_matrimonial_client  in ('4','9') then statut_matrimonial_client_C = '1';/*regroupement de la modalité manquante(9) et la modalité 4*/
	else if statut_matrimonial_client  in('0','1','5') then statut_matrimonial_client_C = '2'; /*regroupement des modalités 0, 1 et 5 */
	else if statut_matrimonial_client = '2' then statut_matrimonial_client_C = '3';  /* pour la modalité '2' */
	else statut_matrimonial_client_C = '4'; /* pour le reste */
run;

/* croisement de la nouvelle variable "statut_matrimonial_client_C" avec "defaut_paiement" */
proc freq data = projet.table_apprentissage;
	tables statut_matrimonial_client_C * defaut_paiement;
run; /* la catégorisation est finale*/


/* croisement entre type_residence_client * defaut_paiement */
proc freq data = projet.table_apprentissage;
	tables type_residence_client * defaut_paiement;
run;

/*codage de la modalité type_residence_client */
data projet.table_apprentissage; 
	set projet.table_apprentissage; 
	if type_residence_client = 'M' then type_residence_client_C = '1'; /* manquante*/
	else if type_residence_client = 'O' then type_residence_client_C = '2';
	else if type_residence_client = 'P' then type_residence_client_C = '3';
	else type_residence_client_C = '4';
run;


/* croisement de la nouvelle variable "type_residence_client_C" avec "defaut_paiement" */
proc freq data = projet.table_apprentissage;
	tables type_residence_client_C * defaut_paiement;
run;

									/************************************************************************/
									/*  		   DISCRETISATION DES PREDICTEURS QUALNTITATIFS			    */
									/************************************************************************/

/* croisement de la variable "retard_courant" avec "defaut_paiement" */
proc freq data = projet.table_apprentissage;
	tables retard_courant * defaut_paiement;
run;

/*codage de la variable retard_courant */
data projet.table_apprentissage; 
	set projet.table_apprentissage; 
	if retard_courant = 0 then retard_courant_C = '1';/* Aucun retard de paiement*/
	else retard_courant_C = '2';
run;

/* croisement de la nouvelle variable "retard_courant_C" avec "defaut_paiement" */
proc freq data = projet.table_apprentissage;
	tables retard_courant_C * defaut_paiement;
run;

/* croisement de la variable "retard_max" avec "defaut_paiement" */
proc freq data = projet.table_apprentissage;
	tables retard_max_6derniers_mois * defaut_paiement;
run;

data projet.table_apprentissage; 
	set projet.table_apprentissage; 
	if retard_max_6derniers_mois in(.,0,-997) then retard_max_C = '1'; /*regroupement des modalités 0 -997 et les manquantes represente les nouveaux comptes*/
	else retard_max_C = '2';
run;


/* croisement de la nouvelle variable "retard_max_C" avec "defaut_paiement" */
proc freq data = projet.table_apprentissage;
	tables retard_max_C * defaut_paiement;
run;

/*************************** anciennete compte ****************/
proc freq data = projet.table_apprentissage;
	tables anciennete_compte * defaut_paiement;
run;

/* codage( categorisation) de la variable "anciennete_compte" en "anciennete_compte_C" */

data projet.table_apprentissage;
	set projet.table_apprentissage;
	if anciennete_compte in(0,1) then anciennete_compte_C = '1'; /* pour les valeurs 0 et 1 */	
	else if anciennete_compte = 2 then anciennete_compte_C = '2';
	else anciennete_compte_C = '3'; /*les modalités "3"; "5" et "6" ont des taux de défaut très similaire. 
								Puisque on ne peut sauter une modalité pour la regrouper avec une autre, on inclut donc la modalité "4" dans le groupe*/
run;

proc freq data = projet.table_apprentissage;
	tables anciennete_compte_C * defaut_paiement;
run;



/*creation d'une macro permettant d'avoir les quartiles des valeurs strictement positives des predicteurs quantitatifs */
%macro quartiles_valeurs_positives(variable=);
	proc means data = projet.table_apprentissage Q1 median Q3;
		var &variable.;
		where &variable. > 0;
	run;
%mend;

/* creation d'une autre macro permettant de faire la discretisation d'un predicteur quantitatif en 5 classes  */
%macro discretisation(variable = ,s1 = ,s2 = ,s3 = );
	data projet.table_apprentissage;
		set projet.table_apprentissage;
		if &variable. <= 0 then &variable._C = '1'; /*valeurs <=0 */
		else if &variable. <= &s1. then &variable._C = '2';
		else if &variable. <= &s2. then &variable._C = '3';
		else if &variable. <= &s3. then &variable._C = '4';
		else &variable._C = '5';
	run;
%mend;

/* creation d'une macro permettant d'obtenir la distribution d'une variable quantitative */
%macro distribution(variable = );
	proc freq data = projet.table_apprentissage;
		tables &variable. * defaut_paiement;
	run;
%mend;

/* Appel des macros pour la variable "pct_utilisation_courant_C"*/
%quartiles_valeurs_positives(variable = pct_utilisation_courant);
%discretisation(variable = pct_utilisation_courant,s1 =7.05 ,s2 = 19.84,s3 = 58.64);
%distribution(variable = pct_utilisation_courant_C);
/* les taux de defaut 1 et 2 sont similaires, on les regroupes */

	data projet.table_apprentissage;
		set projet.table_apprentissage;
		if pct_utilisation_courant_C = '1' then pct_utilisation_courant_C = '2';
	run;
	%distribution(variable = pct_utilisation_courant_C);

	/* discretisation de la variable "achat_courant" */

%quartiles_valeurs_positives(variable = achats_courant);
%discretisation(variable = achats_courant,s1 =97.96 ,s2 = 256.52,s3 = 586.49);
%distribution(variable = achats_courant_C);

/* les taux de defaut 4 et 5 sont similaires, on les regroupes */
	data projet.table_apprentissage;
		set projet.table_apprentissage;
		if achats_courant_C = '5' then achats_courant_C = '4';
	run;
	%distribution(variable = achats_courant_C);



/* discretisation de la variable "solde_courant_autres_pct_limite" */
/* renommons la variable "solde_courant_autres_pct_limite"  par "solde_courant_autre_pct_limite" */
	data projet.table_apprentissage;
		set projet.table_apprentissage;
		rename solde_courant_autres_pct_limite = solde_courant_autre_pct_limite;
	run;

%quartiles_valeurs_positives(variable = solde_courant_autre_pct_limite);
%discretisation(variable = solde_courant_autre_pct_limite,s1 =24.97 ,s2 = 48.43,s3 = 82.91);
%distribution(variable = solde_courant_autre_pct_limite_C);

/* puisque 1 et 3 ont des taux de défauts similaires, regroupons les modalités 1 ; 2 et 3 dans une meme classe*/
	data projet.table_apprentissage;
		set projet.table_apprentissage;
		if solde_courant_autre_pct_limite_C in('1','2','3')  then solde_courant_autre_pct_limite_C = '1';
	run;
%distribution(variable = solde_courant_autre_pct_limite_C);


/* discretisation de la variable "age_client" */
%quartiles_valeurs_positives(variable = age_client);
%discretisation(variable = age_client,s1 =21 ,s2 = 36,s3 = 54);
%distribution(variable = age_client_C);


/* discretisation de la variable "solde_courant" */
%quartiles_valeurs_positives(variable = solde_courant);
%discretisation(variable = solde_courant,s1 =77.63 ,s2 = 225.65,s3 = 599.36);
%distribution(variable = solde_courant_C);


/* discretisation de la variable "solde_courant_pct_max1to6m" */
%quartiles_valeurs_positives(variable = solde_courant_pct_max1to6m);
%discretisation(variable = solde_courant_pct_max1to6m,s1 =24.13 ,s2 = 56.62,s3 = 117.67);
%distribution(variable = solde_courant_pct_max1to6m_C);

data projet.table_apprentissage;
	set projet.table_apprentissage;
	if solde_courant_pct_max1to6m_C in('3','4','5') then solde_courant_pct_max1to6m_C = '3'; /* regroupement de 4 et 5 */
run;
%distribution(variable = solde_courant_pct_max1to6m_C);


/* discretisation de la variable "pct_utilisation_max1to6m" */
%quartiles_valeurs_positives(variable = pct_utilisation_max_1to6m);
%discretisation(variable = pct_utilisation_max_1to6m,s1 =7.89 ,s2 = 22.92,s3 = 63.91);
%distribution(variable = pct_utilisation_max_1to6m_C);

data projet.table_apprentissage;
	set projet.table_apprentissage;
	if pct_utilisation_max_1to6m_C in('1','2','3') then pct_utilisation_max_1to6m_C = '1'; /* regroupement des modalités 1 2 et 3 */
run;
%distribution(variable = pct_utilisation_max_1to6m_C);



/***********************************************************************************************************/
/* discretisation de la variable "achats_courant_pct_moy_1to6m" */
%quartiles_valeurs_positives(variable = achats_courant_pct_moy_1to6m);
%discretisation(variable = achats_courant_pct_moy_1to6m,s1 =52.92 ,s2 = 115.69,s3 = 233.91);
%distribution(variable = achats_courant_pct_moy_1to6m_C);

data projet.table_apprentissage;
	set projet.table_apprentissage;
	if achats_courant_pct_moy_1to6m_C ='5' then achats_courant_pct_moy_1to6m_C = '4'; /* regroupement de 4 et 5 */
run;
%distribution(variable = achats_courant_pct_moy_1to6m_C);

/**********************************************************************************************************************************************/


/* discretisation de la variable "solde_courant_autres" */
%quartiles_valeurs_positives(variable = solde_courant_autres);
%discretisation(variable = solde_courant_autres,s1 =920.77 ,s2 = 1714.16,s3 = 3020.36);
%distribution(variable = solde_courant_autres_C);

data projet.table_apprentissage;
	set projet.table_apprentissage;
	if solde_courant_autres_C in('2','3','4') then solde_courant_autres_C = '2'; /* regroupement de 2 ; 3 et 4 */
run;
%distribution(variable = solde_courant_autres_C);

/*********************************************************************************************************************************************/

/* discretisation de la variable "avances_courant" */
%quartiles_valeurs_positives(variable = avances_courant);
%discretisation(variable = avances_courant,s1 =60 ,s2 = 161.92,s3 = 400);
%distribution(variable = avances_courant_C);

/*******************************************************************************************************************************************/

/* discretisation de la variable "paiements_courant" */
%quartiles_valeurs_positives(variable = paiements_courant);
%discretisation(variable = paiements_courant,s1 =80 ,s2 = 169.97,s3 = 388.16);
%distribution(variable = paiements_courant_C);

data projet.table_apprentissage;
	set projet.table_apprentissage;
	if paiements_courant_C in('1','2','3') then paiements_courant_C = '1'; /* regroupement des modalités 1 et 2 et 3 */
run;
%distribution(variable = paiements_courant_C);

/********************************************************************************************************************************************************/

/*controler tous les resultats des croisements*/
ods pdf file = 'E:\PROJET\PDF\control_final.pdf';
proc freq data = projet.table_apprentissage;
	tables (retard_courant_C pct_utilisation_courant_C achats_courant_C retard_max_C Anciennete_compte_C solde_courant_autre_pct_limite_C age_client_C solde_courant_C solde_courant_pct_max1to6m_C pct_utilisation_max_1to6m_C achats_courant_pct_moy_1to6m_C solde_courant_autres_C avances_courant_C paiements_courant_C Statut_compte_C statut_matrimonial_client_C type_residence_client_C) * defaut_paiement;
run;
ods pdf close;

/*==================================================================================================================================================*/
/*													  				ESTIMATION DU MODELE			  												*/
/*==================================================================================================================================================*/

/* creation d'une nouvelle table contenant l'identifiant, defaut_paiement et les variables categorisées*/
data projet.table_apprentissage_categ(keep = identifiant_compte defaut_paiement retard_courant_C pct_utilisation_courant_C achats_courant_C retard_max_C Anciennete_compte_C solde_courant_autre_pct_limite_C age_client_C solde_courant_C solde_courant_pct_max1to6m_C pct_utilisation_max_1to6m_C achats_courant_pct_moy_1to6m_C solde_courant_autres_C avances_courant_C paiements_courant_C Statut_compte_C statut_matrimonial_client_C type_residence_client_C);
	set projet.table_apprentissage;
run;

									/************************************************************************/
									/*  		   			REGRESSION LOGISTIQUE			    			*/
									/************************************************************************/

ods pdf file = 'E:\PROJET\PDF\regression_logistique.pdf';
proc logistic data = projet.table_apprentissage_categ outmodel = projet.modele_defaut_paiement;
	class retard_courant_C (param = ref ref = '1');
	class	pct_utilisation_courant_C (param = ref ref = '3');
	class	achats_courant_C (param = ref ref = '1');
	class	retard_max_C (param = ref ref = '1');
	class	Anciennete_compte_C (param = ref ref = '3');
	class	solde_courant_autre_pct_limite_C (param = ref ref = '4');
	class	age_client_C (param = ref ref = '4');
	class	solde_courant_C (param = ref ref = '3');
	class	solde_courant_pct_max1to6m_C (param = ref ref = '1');
	class	pct_utilisation_max_1to6m_C (param = ref ref = '4');
	class	achats_courant_pct_moy_1to6m_C (param = ref ref = '1');
	class	solde_courant_autres_C (param = ref ref = '2');
	class	avances_courant_C (param = ref ref = '1');
	class	paiements_courant_C (param = ref ref = '1');
	class	Statut_compte_C (param = ref ref = '1');
	class	statut_matrimonial_client_C (param = ref ref = '1');
	class	type_residence_client_C(param = ref ref = '1');
	model defaut_paiement(event = '1') = retard_courant_C pct_utilisation_courant_C achats_courant_C retard_max_C Anciennete_compte_C solde_courant_autre_pct_limite_C age_client_C solde_courant_C solde_courant_pct_max1to6m_C pct_utilisation_max_1to6m_C achats_courant_pct_moy_1to6m_C solde_courant_autres_C avances_courant_C paiements_courant_C Statut_compte_C statut_matrimonial_client_C type_residence_client_C/
	selection = stepwise slentry = 0.25 slstay = 0.05;
	output out = projet.prevision_apprentissage(keep = identifiant_compte defaut_paiement proba_defaut_paiement)
	prob = proba_defaut_paiement;
run;
ods pdf close;


/********************************************************************************************************************************************/
proc means data = projet.prevision_apprentissage n nmiss min mean max std;
	var proba_defaut_paiement;
run;

/*******************************************************************************************************************************************************/
/* renommons la variable "solde_courant_autres_pct_limite" en solde_courant_autre_pct_limite"*/
data projet.table_validation;
	set projet.table_apprentissage;
	rename solde_courant_autres_pct_limite = solde_courant_autre_pct_limite;
run;

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/*										 CATEGORISATION DES VARIABLES RETENUES  POUR L'ECHANTILLON DE VALIDATION 									*/
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

data projet.validation_categ(keep = identifiant_compte defaut_paiement retard_courant_C pct_utilisation_courant_C retard_max_C anciennete_compte_C solde_courant_autre_pct_limite_C avances_courant_C paiements_courant_C statut_compte_C statut_matrimonial_client_c type_residence_client_C);
set projet.table_validation;

	if retard_courant = 0 then retard_courant_C = '1';
	else retard_courant_C = '2';

	if pct_utilisation_courant  <= 7.05 then pct_utilisation_courant_C = '2';
	else if pct_utilisation_courant <= 19.84 then pct_utilisation_courant_C = '3';
	else if pct_utilisation_courant <= 58.64 then pct_utilisation_courant_C = '4';
	else pct_utilisation_courant = '5';

	if retard_max_6derniers_mois in(.,0,-997) then retard_max_C = '1';
	else retard_max_C = '2';

	if anciennete_compte in(0,1) then anciennete_compte_C = '1'; 	
	else if anciennete_compte = 2 then anciennete_compte_C = '2';
	else anciennete_compte_C = '3'; 

	if solde_courant_autre_pct_limite <= 48.43 then solde_courant_autre_pct_limite_C = '1';
	else if solde_courant_autre_pct_limite <= 82.91 then solde_courant_autre_pct_limite_C = '4';
	else solde_courant_autre_pct_limite_C = '5';

	if avances_courant <=0 then avances_courant_C = '1';
	else if avances_courant <= 60 then avances_courant_C = '2';
	else if avances_courant <= 161.92 then avances_courant_C = '3';
	else if avances_courant <= 400 then avances_courant_C = '4';		
	else avances_courant_C = '5';

	if paiements_courant <= 169.97 then paiements_courant_C = '1'; 
	else if paiements_courant <= 388.16 then paiements_courant_C = '4'; 
	else paiements_courant_C = '5';

	if statut_compte = 'O' then statut_compte_C = '1';
	else statut_compte_C = '2';

	if statut_matrimonial_client  in ('4','9') then statut_matrimonial_client_C = '1';
	else if statut_matrimonial_client  in('0','1','5') then statut_matrimonial_client_C = '2'; 
	else if statut_matrimonial_client = '2' then statut_matrimonial_client_C = '3';  
	else statut_matrimonial_client_C = '4'; 

	if type_residence_client = 'M' then type_residence_client_C = '1'; 
	else if type_residence_client = 'O' then type_residence_client_C = '2';
	else if type_residence_client = 'P' then type_residence_client_C = '3';
	else type_residence_client_C = '4';

run;


/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/*																	SCORING DU MODELE															    */
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
proc logistic inmodel = projet.modele_defaut_paiement;
	score data = projet.validation_categ
	out = projet.validation(keep = Identifiant_compte defaut_paiement P_1);
run;

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/*												ESTIMATION  DE L'ECHANTILLON  DE VALIDATION														    */
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

proc logistic data = projet.validation;
	model defaut_paiement(event = '1') = p_1;
run;


/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*																FIN DE LA MODELISATION 															   */
/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
