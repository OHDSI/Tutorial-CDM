/*****************************/
/* Standard Vocabulary Introduction */
/*****************************/

/* select from concept table */
SELECT * FROM concept WHERE concept_id = 313217

/* or... */
SELECT * FROM concept WHERE concept_code = '49436004';

/* select from vocabulary table */
SELECT * FROM vocabulary
order BY vocabulary_id;

SELECT * FROM concept
WHERE concept_name = 'Atrial fibrillation'
AND vocabulary_id = 'SNOMED';

/* Concept ID vs Concpet Code */
SELECT * FROM concept WHERE concept_code = '1001';

/* Concept by name */
SELECT * FROM concept WHERE concept_name = 'Atrial fibrillation';

/* Find relationship for Atrial fibrillation */
SELECT * FROM concept_relationship WHERE concept_id_1 = 44821957
ORDER BY relationship_id;

/* Find Maps to relationship for Atrial fibrillation */
SELECT * FROM concept_relationship WHERE concept_id_1 = 44821957 AND relationship_id = 'Maps to';

/* Find non-standard Concepts from other vocabularies */
/* ICD-9 */
SELECT * FROM concept WHERE concept_code = '427.31';
SELECT * FROM concept_relationship JOIN concept ON concept_id = concept_id_2 AND relationship_id = 'Maps to'
WHERE concept_id_1 = 44821957;
/* Read */
SELECT * FROM concept WHERE concept_code = 'G573000';
SELECT * FROM concept_relationship JOIN concept ON concept_id = concept_id_2 AND relationship_id = 'Maps to'
WHERE concept_id_1 = 45500085;
/* ICD-10 */
SELECT * FROM concept WHERE concept_code = 'I48.0';
SELECT * FROM concept_relationship JOIN concept ON concept_id = concept_id_2 AND relationship_id = 'Maps to'
WHERE concept_id_1 in ('35207784','45581776');

/* Exploring Relationships */
SELECT * FROM concept_relationship WHERE concept_id_1 = 313217;

/* Find descriptive relationship for Atrial fibrillation */
SELECT cr.relationship_id, c.* 
FROM concept_relationship cr 
JOIN concept c ON cr.concept_id_2 = c.concept_id 
WHERE cr.concept_id_1 = 313217;

/* Find max level of separation for Atrial fibrillation */
SELECT max_levels_of_separation, c.* 
FROM concept_ancestor ca, concept c 
WHERE ca.descendant_concept_id = 313217 /* Atrial fibrillation */ 
	AND ca.ancestor_concept_id = c.concept_id 
ORDER BY max_levels_of_separation
; 

/* Find descendants of a concept */
SELECT max_levels_of_separation, c.* 
FROM concept_ancestor ca, concept c 
WHERE ca.ancestor_concept_id = 44784217 /* cardiac arrythmia */ 
AND ca.descendant_concept_id = c.concept_id 
ORDER BY max_levels_of_separation;

/* Find gastrointestinal bleeding */
SELECT * FROM concept WHERE concept_name = 'Upper gastrointestinal bleeding';

SELECT * FROM concept WHERE lower(concept_name) LIKE '%upper gastrointestinal%';

/* Find optimal Ancestor */
SELECT max_levels_of_separation, c.* 
FROM concept_ancestor ca, concept c 
WHERE ca.descendant_concept_id = 4332645 /* Upper gastrointestinal haemorrhage */
	AND ca.ancestor_concept_id = c.concept_id 
ORDER BY max_levels_of_separation; 

/* Check content of Concept by screening the Descendants */
SELECT max_levels_of_separation, c.* 
FROM concept_ancestor ca, concept c 
WHERE ca.ancestor_concept_id = 4291649 /* Upper gastrointestinal hemorrhage */
	AND ca.descendant_concept_id = c.concept_id 
ORDER BY max_levels_of_separation;

/* Find asthma */
SELECT * FROM concept WHERE LOWER(concept_name) LIKE 'plague';
/* Find the plague */
SELECT * FROM concept WHERE LOWER(concept_name) LIKE 'plague';
/* Find ingrown toenail */
SELECT * FROM concept WHERE LOWER(concept_name) LIKE 'ingrown toenail';
SELECT * FROM concept_relationship WHERE concept_id_1=40288193;
SELECT * FROM concept WHERE concept_id=139099;

/* Find warfarin active ingredient */
SELECT * FROM concept WHERE concept_name = 'Warfarin';

/* Find clopidogrel by NDC */
SELECT * FROM concept WHERE concept_id='67544050474';
SELECT * FROM concept_relationship WHERE concept_id_1=45867731 and relationship_id='Maps to';
SELECT * FROM concept WHERE concept_id=1322185;

/* Find ingredient Clopidogrel as Ancestor of drug product */
SELECT a.max_levels_of_separation, c.* 
FROM concept_ancestor ca, concept c 
WHERE ca.descendant_concept_id = 1322185 /* clopidogrel 75 MG Oral Tablet [Plavix] */
	AND ca.ancestor_concept_id = c.concept_id;
ORDER BY max_levels_of_separation;

/* Find other drugs that contains Warfarin AND Dabigratran */
SELECT max_levels_of_separation, c.* 
FROM concept_ancestor ca, concept c 
WHERE ca.ancestor_concept_id = 1310149 /* Warfarin or 1322184 Clopidogrel */
	AND ca.descendant_concept_id = c.concept_id 
ORDER BY max_levels_of_separation; 

/* Find members of a drug class */
SELECT max_levels_of_separation, c.* 
FROM concept_ancestor ca, concept c 
WHERE ca.ancestor_concept_id = 21600961 /* ANTITHROMBOTIC AGENTS */
	AND ca.descendant_concept_id = c.concept_id 
	AND c.concept_class_id = 'Ingredient'
ORDER BY max_levels_of_separation; 

/******************************************************************************
*	CDM Exercises
******************************************************************************/

/******************************************************************************
*	(Exercise 1) Warfarin New Users
******************************************************************************/

WITH CTE_DRUG_INDEX AS (
	SELECT de.PERSON_ID, MIN(de.DRUG_EXPOSURE_START_DATE) AS INDEX_DATE
	FROM DRUG_EXPOSURE de
	WHERE de.DRUG_CONCEPT_ID IN (
		SELECT DESCENDANT_CONCEPT_ID 
		FROM CONCEPT_ANCESTOR WHERE ANCESTOR_CONCEPT_ID = 1310149 /*warfarin*/
	)
	GROUP BY de.PERSON_ID
)
SELECT i.PERSON_ID, i.INDEX_DATE, op.OBSERVATION_PERIOD_START_DATE, op.OBSERVATION_PERIOD_END_DATE,
	(i.INDEX_DATE-op.OBSERVATION_PERIOD_START_DATE) AS DAYS_BEFORE_INDEX
FROM CTE_DRUG_INDEX i
	JOIN OBSERVATION_PERIOD op
		ON op.PERSON_ID = i.PERSON_ID
		AND i.INDEX_DATE BETWEEN op.OBSERVATION_PERIOD_START_DATE AND op.OBSERVATION_PERIOD_END_DATE
WHERE (i.INDEX_DATE-op.OBSERVATION_PERIOD_START_DATE) >= 180
ORDER BY i.PERSON_ID

/******************************************************************************
*	(Exercise 2) Warfarin New Users 65 or Older at Index
******************************************************************************/

WITH CTE_DRUG_INDEX AS (
	SELECT de.PERSON_ID, MIN(de.DRUG_EXPOSURE_START_DATE) AS INDEX_DATE
	FROM DRUG_EXPOSURE de
	WHERE de.DRUG_CONCEPT_ID IN (
		SELECT DESCENDANT_CONCEPT_ID FROM CONCEPT_ANCESTOR WHERE ANCESTOR_CONCEPT_ID = 1310149 /*warfarin*/
	)
	GROUP BY de.PERSON_ID
)
SELECT i.PERSON_ID, i.INDEX_DATE, op.OBSERVATION_PERIOD_START_DATE, op.OBSERVATION_PERIOD_END_DATE,
	(i.INDEX_DATE-op.OBSERVATION_PERIOD_START_DATE) AS DAYS_BEFORE_INDEX, 
	EXTRACT(YEAR FROM i.INDEX_DATE)-p.YEAR_OF_BIRTH AS AGE_AT_INDEX
FROM CTE_DRUG_INDEX i
	JOIN OBSERVATION_PERIOD op
		ON op.PERSON_ID = i.PERSON_ID
		AND i.INDEX_DATE BETWEEN op.OBSERVATION_PERIOD_START_DATE AND op.OBSERVATION_PERIOD_END_DATE
	JOIN PERSON p
		ON p.PERSON_ID = i.PERSON_ID
WHERE (i.INDEX_DATE-op.OBSERVATION_PERIOD_START_DATE) >= 180
AND EXTRACT(YEAR FROM i.INDEX_DATE)-p.YEAR_OF_BIRTH >= 65
ORDER BY i.PERSON_ID

/******************************************************************************
*	(Exercise 3) Warfarin New Users With Prior AFIB
******************************************************************************/

WITH CTE_DRUG_INDEX AS (
	SELECT de.PERSON_ID, MIN(de.DRUG_EXPOSURE_START_DATE) AS INDEX_DATE
	FROM DRUG_EXPOSURE de
	WHERE de.DRUG_CONCEPT_ID IN (
		SELECT DESCENDANT_CONCEPT_ID FROM CONCEPT_ANCESTOR WHERE ANCESTOR_CONCEPT_ID = 1310149 /*warfarin*/
	)
	GROUP BY de.PERSON_ID
), 
CTE_DRUG_NEW_USERS AS (
	SELECT i.PERSON_ID, i.INDEX_DATE, op.OBSERVATION_PERIOD_START_DATE, op.OBSERVATION_PERIOD_END_DATE,
		(i.INDEX_DATE-op.OBSERVATION_PERIOD_START_DATE) AS DAYS_BEFORE_INDEX
	FROM CTE_DRUG_INDEX i
		JOIN OBSERVATION_PERIOD op
			ON op.PERSON_ID = i.PERSON_ID
			AND i.INDEX_DATE BETWEEN op.OBSERVATION_PERIOD_START_DATE AND op.OBSERVATION_PERIOD_END_DATE
	WHERE (i.INDEX_DATE-op.OBSERVATION_PERIOD_START_DATE) >= 180
)
SELECT nu.*, MAX(nu.INDEX_DATE-co.CONDITION_START_DATE) AS DAYS_OF_CLOSEST_AFIB_PRIOR_TO_INDEX
FROM CTE_DRUG_NEW_USERS nu
	JOIN CONDITION_OCCURRENCE co
		ON co.PERSON_ID = nu.PERSON_ID
		AND co.CONDITION_START_DATE BETWEEN nu.OBSERVATION_PERIOD_START_DATE AND nu.OBSERVATION_PERIOD_END_DATE
WHERE co.CONDITION_CONCEPT_ID IN (
		SELECT DESCENDANT_CONCEPT_ID FROM CONCEPT_ANCESTOR WHERE ANCESTOR_CONCEPT_ID = 	313217 /*Atrial fibrillation*/		
)
AND co.CONDITION_START_DATE < nu.INDEX_DATE
GROUP BY nu.PERSON_ID, nu.INDEX_DATE, nu.OBSERVATION_PERIOD_START_DATE, nu.OBSERVATION_PERIOD_END_DATE, nu.DAYS_BEFORE_INDEX
ORDER BY nu.PERSON_ID
	
	
	
