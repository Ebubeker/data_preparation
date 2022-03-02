DROP FUNCTION IF EXISTS compute_impedances;
CREATE OR REPLACE FUNCTION public.compute_impedances(elevs float[], linkLength float, lengthInterval float)
 RETURNS TABLE (imp float, rs_imp float)
 LANGUAGE plpgsql
AS $function$
DECLARE
    slope float;
   	r_slope float;
	i integer := 1;
	j float;
	v integer;
	imp float;
	len_array integer := array_length(elevs,1);
	lengthSection float := lengthInterval;
	lengthLastSection float;
	sumImpedance float := 0.0;
	sumImpedanceReverse float := 0.0;
BEGIN
	IF linkLength > (2*lengthInterval) THEN
		lengthLastSection = linkLength - ((len_array - 2) * lengthInterval);
	ELSEIF linkLength > lengthInterval AND linkLength < (2*lengthInterval) THEN
		lengthLastSection = linkLength/2;
		lengthSection = linkLength/2;
	ELSE
		lengthLastSection = linkLength;	
    END IF;
		
	LOOP
		IF len_array = 1 THEN EXIT;
		END IF;
		IF (len_array) - 1 = i THEN 
			lengthSection = lengthLastSection;
		END IF; 
		
		slope = ((elevs[i+1] - elevs[i])/lengthSection)*100;
		v = 1;
	    FOREACH j in ARRAY ARRAY[slope,-slope]
	    LOOP
	        IF j > 9 THEN 
	        	imp = 3;
	        ELSEIF j < 12 AND j > 0 THEN
	        	imp = 1+j*0.0430815;
	        ELSEIF j < 0 AND j > -9 THEN 
	        	imp = 1+j*0.0363248;
	        ELSEIF j < -9 THEN
	        	imp = 0.65;
	        ELSEIF j = 0 THEN 
	        	imp = 1;
	        END IF;
	       	
	       	IF v = 1 THEN 
	       		sumImpedance = sumImpedance + ((lengthSection/linkLength) * imp); 	
	       	ELSE 
	       		sumImpedanceReverse = sumImpedanceReverse + ((lengthSection/linkLength) * imp);
	       	END IF;
	       
	       	v = v + 1;     
	    END LOOP;
		/*
		RAISE NOTICE '#########################';
	   	RAISE NOTICE 'Section %',i;
	    RAISE NOTICE '%',slope;
	   	RAISE NOTICE '%',lengthSection;
	   	RAISE NOTICE '%', sumImpedance;
	  	RAISE NOTICE '%', elevs[i+1];
	  	*/

	   	EXIT WHEN i = len_array - 1;
	   	i = i + 1;
   END LOOP;   
   RETURN query SELECT sumImpedance-1, sumImpedanceReverse-1;

END ;
$function$ IMMUTABLE;


/*
EXPLAIN ANALYZE 
select compute_impedances(ARRAY[592.7148121482129,592.9108133538796,592.8564161772507,592.9966675210214],25,10)
  
EXPLAIN ANALYZE 
SELECT * 
FROM compute_impedances(ARRAY[592.7148121482129,592.9108133538796,592.8564161772507,592.9966675210214,593.5142995351175,593.7934132187218,594.0791123343638,594.4123340711714,595.0709339933488,595.297176661014,595.5693572768498,595.9848412527108,596.8401692540409,597.3171319612385,597.3482358264915,597.5382529434738,597.8022676643865,597.8740809185631,597.823075664003,597.7863504450027,597.626674683176,597.6343312386101,597.4277702839657,597.4008755308755,595.8668147549672,595.8660641137426,595.7965538931242,595.6454700224763,595.0920134259331,594.637849977284,594.7157834949176,594.8803722155301,594.9887926115971,594.9830892260971,594.9870887111837,595.0787212146299,595.0386387688128,595.0324550215119,594.8250819105949,594.7880532571487,594.8995285649445,594.8810906098278,594.6393061703341,594.5495462993056,594.659993488184,594.9117694793237,594.8561671328405,595.1014832310566,595.9805443687969,596.2352886423453,596.6661575732143,596.8519273771171,596.9980204380629,597.5609773647477,597.5791774155083,597.4665069723288,597.6586808056799,597.485007468097,597.2002620872586,597.1963692359632,597.2027716376099,597.3514613004011,597.5291349479928,597.7423810451334,597.8229651815739,598.3487641240755,598.9325624511746,599.1410746685413,599.5569045340294,599.6335839517587,600.0134635692586,600.0129365392264,600.182788759895,600.2291691233494,600.29322494889,600.5026235315236,600.588326757217,600.7822175536718,600.7889289583835,600.8583938103352,600.8506023673,600.8594569857722,600.855095798295,600.8699011121003,600.8948367881649,600.9158160563479,600.9308420352094,600.9317041421716,601.0112494866629,601.1194077913335,601.1447172081055,601.2190570375012,601.1755003536814,601.2574300612171,601.4244977205623,601.3280721278472,601.4095292607226,601.4469409424296,601.343675456267,601.2644166539546,601.448225363388,601.764308894998,601.9141684209388,601.9285510317757,602.2221844031513,602.927047984513,603.209684715867,603.4120463058216,603.609247115536,604.0931344921927,604.3979434665107,604.0595104609955,604.1208265697768,604.4242234358535,604.2729929211542,604.1726212874402,604.0363343203236,603.9131865304082,603.7376785831837,603.6344507785851,603.1815415276134,603.021235237828,602.8921379501912,602.8012998289823,602.8292367257493,602.8971681366721,602.9116349735643,602.8851462845998,602.8320536308945,602.8306007032874,602.8344996324383,602.8328210595299,603.0523886491386,603.165058943027,603.0310286699672,602.9595157706631,602.9181726332915]::FLOAT[],
1353.3649483199176, 10.0);
*/

