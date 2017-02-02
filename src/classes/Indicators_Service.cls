public class Indicators_Service {
	
	public static List<Indicator> getIndicatorsForObject(SObject sob) {
		List<Indicator> result = new List<Indicator>();
		for(Indicator__mdt config : [SELECT DeveloperName, Grid_Order__c,
									 Field_API_Name__c, Enabled_Color__c,
									 Contains_Value__c, Display_Value__c,
									 Disabled_Color__c, Type__c, Hover_Text__c
									 FROM Indicator__mdt
									 WHERE Entity__c = :sob.getSObjectType().getDescribe().getName()
									 ORDER BY Grid_Order__c]) {
										 result.add(evaluateIndicator(config,sob));
									 }
		return result;
	}

	public static List<String> getFieldNamesForObject(SObjectType t) {
		Set<String> result = new Set<String>();
		for(Indicator__mdt config : [SELECT DeveloperName,  Field_API_Name__c FROM Indicator__mdt WHERE Field_API_Name__c != null AND Entity__c = :t.getDescribe().getName() ]) {
			result.add(config.Field_API_Name__c);
		}
		return new List<String>(result);
	}

	private static Indicator evaluateIndicator(Indicator__mdt config, SObject sob) {
		Object field = '';
		if(String.isNotBlank(config.Field_API_Name__c)) {
			field = sob.get(config.Field_API_Name__c);
		}

		Boolean enabled = false;
		Boolean display = true;
		String iType = '';
		if(config.Type__c == 'Contains') {
			if(String.isNotBlank((String)field) && String.isNotBlank(config.Contains_Value__c)) {
				enabled = ((String)field).contains(config.Contains_Value__c);
			}

		} else if(config.Type__c == 'Boolean') {
			enabled = (Boolean)field;
		} else if(config.Type__c == 'Is Not Null') {
			if(String.isNotBlank(String.valueOf(field)))   //String.isNotBlank((String)field)
				enabled = true;
		} else if(config.Type__c == 'Greater Than') {
			if(field != null && String.isNotBlank(config.Contains_Value__c)) {
				enabled = (Decimal.valueOf(String.valueOf(field)) > Decimal.valueOf(config.Contains_Value__c));
			}
		} else if(config.Type__c == 'Less Than') {
			if(field != null && String.isNotBlank(config.Contains_Value__c)) {
				enabled = (Decimal.valueOf(String.valueOf(field)) < Decimal.valueOf(config.Contains_Value__c));
			}
		} else if(config.Type__c == 'Blank') {
			enabled = false;
			display = false;
		}

		// include null option as TEXT type and first to avoid null pointer exceptions and accomodate Blank indicator  
		if (config.Display_Value__c == null || (config.Display_Value__c.length() <= 4 && !spriteSet.contains(config.Display_Value__c))) {
			system.debug('Using text display for ' + config.Display_Value__c);
			iType = 'TEXT';
		} else if (Pattern.matches('custom[0-9]{1,3}',config.Display_Value__c)) {
			system.debug('Custom sprite found for ' + config.Display_Value__c);
			iType = 'CUSTOM_SPRITE';
		} else if (spriteSet.contains(config.Display_Value__c)) {
			system.debug('Standard sprite found for ' + config.Display_Value__c);
			iType = 'STANDARD_SPRITE'; 
		} else {
			system.debug('No sprite found for ' + config.Display_Value__c + ' trying to add an error');
			// ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'No valid icon found for Display Value ' + config.Display_Value__c + 'Check Indicator record ' + config.DeveloperName));
			iType = 'TEXT';
			throw new WeathervaneException('No valid icon found for Display Value ' + config.Display_Value__c + '. Check Indicator record ' + config.DeveloperName);
		}
		
		return new Indicator(config.Display_Value__c, enabled ? config.Enabled_Color__c : config.Disabled_Color__c, display, config.Hover_Text__c, iType);
	}

	public static Set<String> spriteSet {
		get {
			if (spriteSet == null) {
/*				if (Cache.Org.contains('indicatorbar.partition1.spriteSet')) {
					return (Set<String>)Cache.Org.get('indicatorbar.partition1.spriteSet');
				} else {
*/					
					PageReference pr = new PageReference('/resource/sldswv/assets/icons/standard-sprite/svg/symbols.svg');
					String content = pr.getContent().toString();
					Pattern xmlid = Pattern.compile('id=\"[a-zA-Z_]+');
					Matcher idMatcher = xmlid.matcher(content);
					Set<String> idNames = new Set<String>();

					if (idMatcher.find()) {
					    do {
					        idNames.add(idMatcher.group().substringAfter('="'));
					    } while (idMatcher.find());
					}
					// Cache.Org.put('indicatorbar.partition1.spriteSet',idNames);
					return idNames;
				}
			// }
			return spriteSet;
		}
		private set;
	} 

	public class Indicator {
		public string Color {get;set;}
		public string Value {get;set;}
		public Boolean Display {get;set;}
		public string Hover {get;set;}
		public String iType {get;set;}

		public Indicator(String value, String color, Boolean display, String hover, String iType) {
			this.Value = value; this.Color = color; this.Display = display; this.Hover = hover; this.iType = iType;
		}
	}

	public class WeathervaneException extends Exception {}
}