-- __/\\\\\\\\\\\__/\\\\\_____/\\\__/\\\\\\\\\\\\\\\_____/\\\\\_________/\\\\\\\\\_________/\\\\\\\________/\\\\\\\________/\\\\\\\________/\\\\\\\\\\________________/\\\\\\\\\_______/\\\\\\\\\_____        
--  _\/////\\\///__\/\\\\\\___\/\\\_\/\\\///////////____/\\\///\\\_____/\\\///////\\\_____/\\\/////\\\____/\\\/////\\\____/\\\/////\\\____/\\\///////\\\_____________/\\\\\\\\\\\\\___/\\\///////\\\___       
--   _____\/\\\_____\/\\\/\\\__\/\\\_\/\\\_____________/\\\/__\///\\\__\///______\//\\\___/\\\____\//\\\__/\\\____\//\\\__/\\\____\//\\\__\///______/\\\_____________/\\\/////////\\\_\///______\//\\\__      
--    _____\/\\\_____\/\\\//\\\_\/\\\_\/\\\\\\\\\\\____/\\\______\//\\\___________/\\\/___\/\\\_____\/\\\_\/\\\_____\/\\\_\/\\\_____\/\\\_________/\\\//_____________\/\\\_______\/\\\___________/\\\/___     
--     _____\/\\\_____\/\\\\//\\\\/\\\_\/\\\///////____\/\\\_______\/\\\________/\\\//_____\/\\\_____\/\\\_\/\\\_____\/\\\_\/\\\_____\/\\\________\////\\\____________\/\\\\\\\\\\\\\\\________/\\\//_____    
--      _____\/\\\_____\/\\\_\//\\\/\\\_\/\\\___________\//\\\______/\\\______/\\\//________\/\\\_____\/\\\_\/\\\_____\/\\\_\/\\\_____\/\\\___________\//\\\___________\/\\\/////////\\\_____/\\\//________   
--       _____\/\\\_____\/\\\__\//\\\\\\_\/\\\____________\///\\\__/\\\______/\\\/___________\//\\\____/\\\__\//\\\____/\\\__\//\\\____/\\\___/\\\______/\\\____________\/\\\_______\/\\\___/\\\/___________  
--        __/\\\\\\\\\\\_\/\\\___\//\\\\\_\/\\\______________\///\\\\\/______/\\\\\\\\\\\\\\\__\///\\\\\\\/____\///\\\\\\\/____\///\\\\\\\/___\///\\\\\\\\\/_____________\/\\\_______\/\\\__/\\\\\\\\\\\\\\\_ 
--         _\///////////__\///_____\/////__\///_________________\/////_______\///////////////_____\///////________\///////________\///////_______\/////////_______________\///________\///__\///////////////__

-- Your Name: Park Chang Whan
-- By submitting, you declare that this work was completed entirely by yourself.
 
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q1

SELECT DISTINCT first_name, last_name
FROM staff
	JOIN profile ON staff.id = profile.staff_id
WHERE profile.role_id = (SELECT id 
							FROM role 
							WHERE role_name = 'team Lead');

-- END Q1
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q2

SELECT DISTINCT last_name, first_name, team.team_name
FROM staff
	JOIN profile ON staff.id = profile.staff_id
	JOIN team ON profile.team_id = team.id
    JOIN team AS parent ON team.parent_id = parent.id
WHERE parent.team_name = 'Victoria'
ORDER BY last_name;

-- END Q2
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q3

SELECT DISTINCT first_name, last_name
FROM staff
	JOIN profile ON staff.id = profile.staff_id
	JOIN team ON profile.team_id = team.id
WHERE team_name = 'Errinundra'
	AND valid_from <= '2021/05/13'
    AND '2021/04/13' <= valid_until;

-- END Q3
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q4

SELECT first_name, last_name
FROM staff
	JOIN profile ON staff.id = profile.staff_id
    JOIN role ON role.id = profile.role_id
    JOIN team ON team.id = profile.team_id
WHERE '2021/05/23' BETWEEN valid_from AND valid_until
	AND role_name = 'Agent'
GROUP BY first_name, last_name

-- Only if sum = 1 then we know staff ONLY worked at Werrikimbe
HAVING SUM(CASE WHEN team_name = 'Werrikimbe' THEN 1 ELSE 2 END) = 1;

-- END Q4
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q5

SELECT 
	team_name
	,MONTH(response_time) AS month
    ,AVG(agent_quality) as averageAQ
FROM survey_response
	NATURAL JOIN profile 
    JOIN team on team.id = profile.team_id
GROUP BY team_name, MONTH(response_time)
ORDER BY AVG(agent_quality) DESC;

-- END Q5
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q6


SELECT 
	MONTH(response_time) as month 
    
    , -- NPS(rounded) = % promoters (score 9-10) - % detractors (score 0-6) 
	  ROUND((SUM(CASE WHEN promoter_score BETWEEN 9 AND 10 THEN 1 ELSE 0 END)/COUNT(1) 
			- SUM(CASE WHEN promoter_score BETWEEN 0 AND 6 THEN 1 ELSE 0 END)/COUNT(1))
			* 100) as NPS
FROM survey_response
WHERE promoter_score IS NOT NULL
GROUP BY MONTH(response_time);

-- END Q6
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q7

SELECT COUNT(first_call_resolution)/COUNT(1) * 100 AS 'Tatjana''s enhanced participation'
FROM call_record
	LEFT JOIN survey_response ON call_record.survey_response_id = survey_response.id
	JOIN profile ON call_record.profile_ref = profile.profile_ref
    JOIN staff ON staff.id = profile.staff_id
WHERE MONTH(call_time) = 6
    AND first_name = 'Tatjana' 
    AND last_name = 'Pryor';

-- END Q7
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q8


SELECT first_name
	    ,last_name
		,SUM(CASE WHEN first_call_resolution = 2 THEN 1 ELSE 0 END) AS FCR_count
FROM survey_response
	NATURAL JOIN profile
	JOIN staff ON profile.staff_id = staff.id
WHERE response_time BETWEEN '2021/06/01' AND '2021/06/17 23:59:59'
GROUP BY staff_id

-- Looking for all agents with the lowest FCR_count score (Allows for multiple agents)
HAVING FCR_count = (
					SELECT SUM(CASE WHEN first_call_resolution = 2 THEN 1 ELSE 0 END) AS FCR_count
				    FROM survey_response
				    NATURAL JOIN profile
					WHERE response_time BETWEEN '2021/06/01' AND '2021/06/17 23:59:59'
					GROUP BY staff_id
					ORDER BY FCR_count
					LIMIT 1 -- We only want the minimum FCR counts
				   );
                                  
-- END Q8
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q9

SELECT AVG(AQ) AS Average_AQ_with_Team_Lead, AVG(agent_quality) AS Overall_Average_AQ
FROM(
		-- Getting table with all agent qualities from calls with team lead involved
		SELECT call_ref, SUM(agent_quality) as AQ
		FROM call_record
		LEFT JOIN survey_response on call_record.survey_response_id = survey_response.id
		GROUP BY call_ref
		
        -- Criteria to choosing agent qualities per call_ref
			-- call_leg > 1 (1)
            -- agent_quality is not null (2)
            -- at least one profile_ref matching profile_ref of team_lead (3)
        HAVING COUNT(call_leg) > 1 -- (1)
			AND MAX(agent_quality) IS NOT NULL -- (2)
			AND SUM(
					 CASE 
					 WHEN call_record.profile_ref IN (
													  SELECT profile_ref
													  FROM profile
													  JOIN role ON profile.role_id = role.id
													  WHERE role_name = 'team Lead'
													 ) THEN 1
						ELSE 0
						END
				     ) != 0 -- (3)
	 ) AS overall_AQs_team_lead
     
     -- Getting table with all the agent_ratings to solve for Overall Average AQ
     RIGHT JOIN (
					SELECT call_ref, agent_quality
					FROM call_record 
                    JOIN survey_response ON call_record.survey_response_id = survey_response.id
                    WHERE agent_quality IS NOT NULL
				) AS total_AQs ON total_AQs.call_ref = overall_AQs_team_lead.call_ref;


-- END Q9
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- BEGIN Q10

SELECT first_name, last_name
FROM profile
JOIN staff ON staff.id = profile.staff_id
LEFT JOIN (
			SELECT staff_id as tat_id, team_id 
            FROM profile WHERE staff_id = 2
		   ) AS tatjana ON tatjana.team_id = profile.team_id
GROUP BY profile.staff_id, first_name, last_name

-- If sum of tat_id per staff is NULL, 
-- 	the staff did not work in ANY of the teams that Tatjana worked in
HAVING SUM(tat_id) IS NULL
	
    -- Checking if the staff worked in all of the other teams that Tatjana did not work in
    AND COUNT(DISTINCT profile.team_id) 
			= (SELECT COUNT(1) FROM team WHERE has_staff = 1) 
				- (SELECT COUNT(DISTINCT team_id) FROM profile WHERE staff_id = 2);

-- END Q10
-- ____________________________________________________________________________________________________________________________________________________________________________________________________________
-- END OF ASSIGNMENT