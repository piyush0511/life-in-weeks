import Foundation

public struct Country: Identifiable, Equatable, Sendable, Hashable {
    public let code: String
    public let name: String
    public let capital: String
    public let cities: [String]
    public let region: Region

    public init(
        code: String,
        name: String,
        capital: String,
        cities: [String] = [],
        region: Region
    ) {
        self.code = code
        self.name = name
        self.capital = capital
        self.cities = cities
        self.region = region
    }

    public var id: String { code }

    public var flag: String {
        code.uppercased().unicodeScalars.compactMap {
            Unicode.Scalar($0.value + 0x1F1A5)
        }.reduce("") { $0 + String($1) }
    }

    /// All place names associated with this country: country, capital, and
    /// major cities. Deduplicated to avoid e.g. "Singapore" appearing twice
    /// (country name and capital both Singapore).
    public var allPlaceNames: [String] {
        var seen = Set<String>()
        var ordered: [String] = []
        for name in [name, capital] + cities {
            if !seen.contains(name) {
                seen.insert(name)
                ordered.append(name)
            }
        }
        return ordered
    }

    public enum Region: String, CaseIterable, Codable, Sendable, Identifiable {
        case africa = "Africa"
        case americas = "Americas"
        case asia = "Asia"
        case europe = "Europe"
        case oceania = "Oceania"

        public var id: String { rawValue }
    }
}

public enum Countries {
    public static let all: [Country] = [
        .init(code: "AF", name: "Afghanistan", capital: "Kabul", cities: ["Kandahar", "Herat", "Mazar-i-Sharif"], region: .asia),
        .init(code: "AL", name: "Albania", capital: "Tirana", cities: ["Durrës", "Vlorë"], region: .europe),
        .init(code: "DZ", name: "Algeria", capital: "Algiers", cities: ["Oran", "Constantine"], region: .africa),
        .init(code: "AD", name: "Andorra", capital: "Andorra la Vella", region: .europe),
        .init(code: "AO", name: "Angola", capital: "Luanda", cities: ["Huambo", "Lobito"], region: .africa),
        .init(code: "AG", name: "Antigua and Barbuda", capital: "St. John's", region: .americas),
        .init(code: "AR", name: "Argentina", capital: "Buenos Aires", cities: ["Córdoba", "Rosario", "Mendoza", "Mar del Plata"], region: .americas),
        .init(code: "AM", name: "Armenia", capital: "Yerevan", cities: ["Gyumri"], region: .asia),
        .init(code: "AU", name: "Australia", capital: "Canberra", cities: ["Sydney", "Melbourne", "Brisbane", "Perth"], region: .oceania),
        .init(code: "AT", name: "Austria", capital: "Vienna", cities: ["Salzburg", "Innsbruck", "Graz"], region: .europe),
        .init(code: "AZ", name: "Azerbaijan", capital: "Baku", cities: ["Ganja"], region: .asia),
        .init(code: "BS", name: "Bahamas", capital: "Nassau", cities: ["Freeport"], region: .americas),
        .init(code: "BH", name: "Bahrain", capital: "Manama", cities: ["Muharraq"], region: .asia),
        .init(code: "BD", name: "Bangladesh", capital: "Dhaka", cities: ["Chittagong", "Khulna", "Sylhet"], region: .asia),
        .init(code: "BB", name: "Barbados", capital: "Bridgetown", region: .americas),
        .init(code: "BY", name: "Belarus", capital: "Minsk", cities: ["Brest", "Grodno"], region: .europe),
        .init(code: "BE", name: "Belgium", capital: "Brussels", cities: ["Antwerp", "Ghent", "Bruges", "Liège"], region: .europe),
        .init(code: "BZ", name: "Belize", capital: "Belmopan", cities: ["Belize City"], region: .americas),
        .init(code: "BJ", name: "Benin", capital: "Porto-Novo", cities: ["Cotonou"], region: .africa),
        .init(code: "BT", name: "Bhutan", capital: "Thimphu", cities: ["Paro"], region: .asia),
        .init(code: "BO", name: "Bolivia", capital: "La Paz", cities: ["Santa Cruz", "Cochabamba", "Sucre"], region: .americas),
        .init(code: "BA", name: "Bosnia and Herzegovina", capital: "Sarajevo", cities: ["Mostar", "Banja Luka"], region: .europe),
        .init(code: "BW", name: "Botswana", capital: "Gaborone", cities: ["Francistown"], region: .africa),
        .init(code: "BR", name: "Brazil", capital: "Brasília", cities: ["Rio de Janeiro", "São Paulo", "Salvador", "Recife"], region: .americas),
        .init(code: "BN", name: "Brunei", capital: "Bandar Seri Begawan", region: .asia),
        .init(code: "BG", name: "Bulgaria", capital: "Sofia", cities: ["Plovdiv", "Varna"], region: .europe),
        .init(code: "BF", name: "Burkina Faso", capital: "Ouagadougou", cities: ["Bobo-Dioulasso"], region: .africa),
        .init(code: "BI", name: "Burundi", capital: "Gitega", cities: ["Bujumbura"], region: .africa),
        .init(code: "CV", name: "Cabo Verde", capital: "Praia", cities: ["Mindelo"], region: .africa),
        .init(code: "KH", name: "Cambodia", capital: "Phnom Penh", cities: ["Siem Reap", "Battambang"], region: .asia),
        .init(code: "CM", name: "Cameroon", capital: "Yaoundé", cities: ["Douala"], region: .africa),
        .init(code: "CA", name: "Canada", capital: "Ottawa", cities: ["Toronto", "Vancouver", "Montreal", "Calgary", "Quebec"], region: .americas),
        .init(code: "CF", name: "Central African Republic", capital: "Bangui", region: .africa),
        .init(code: "TD", name: "Chad", capital: "N'Djamena", region: .africa),
        .init(code: "CL", name: "Chile", capital: "Santiago", cities: ["Valparaíso", "Concepción"], region: .americas),
        .init(code: "CN", name: "China", capital: "Beijing", cities: ["Shanghai", "Shenzhen", "Guangzhou", "Chengdu", "Hangzhou"], region: .asia),
        .init(code: "CO", name: "Colombia", capital: "Bogotá", cities: ["Medellín", "Cali", "Cartagena"], region: .americas),
        .init(code: "KM", name: "Comoros", capital: "Moroni", region: .africa),
        .init(code: "CG", name: "Congo", capital: "Brazzaville", cities: ["Pointe-Noire"], region: .africa),
        .init(code: "CD", name: "Congo (DRC)", capital: "Kinshasa", cities: ["Lubumbashi", "Goma"], region: .africa),
        .init(code: "CR", name: "Costa Rica", capital: "San José", cities: ["Alajuela"], region: .americas),
        .init(code: "CI", name: "Côte d'Ivoire", capital: "Yamoussoukro", cities: ["Abidjan"], region: .africa),
        .init(code: "HR", name: "Croatia", capital: "Zagreb", cities: ["Split", "Dubrovnik", "Rijeka"], region: .europe),
        .init(code: "CU", name: "Cuba", capital: "Havana", cities: ["Santiago de Cuba"], region: .americas),
        .init(code: "CY", name: "Cyprus", capital: "Nicosia", cities: ["Limassol", "Larnaca"], region: .europe),
        .init(code: "CZ", name: "Czechia", capital: "Prague", cities: ["Brno", "Ostrava"], region: .europe),
        .init(code: "DK", name: "Denmark", capital: "Copenhagen", cities: ["Aarhus", "Odense"], region: .europe),
        .init(code: "DJ", name: "Djibouti", capital: "Djibouti", region: .africa),
        .init(code: "DM", name: "Dominica", capital: "Roseau", region: .americas),
        .init(code: "DO", name: "Dominican Republic", capital: "Santo Domingo", cities: ["Santiago", "Punta Cana"], region: .americas),
        .init(code: "EC", name: "Ecuador", capital: "Quito", cities: ["Guayaquil", "Cuenca"], region: .americas),
        .init(code: "EG", name: "Egypt", capital: "Cairo", cities: ["Alexandria", "Luxor", "Giza", "Aswan"], region: .africa),
        .init(code: "SV", name: "El Salvador", capital: "San Salvador", cities: ["Santa Ana"], region: .americas),
        .init(code: "GQ", name: "Equatorial Guinea", capital: "Malabo", cities: ["Bata"], region: .africa),
        .init(code: "ER", name: "Eritrea", capital: "Asmara", region: .africa),
        .init(code: "EE", name: "Estonia", capital: "Tallinn", cities: ["Tartu"], region: .europe),
        .init(code: "SZ", name: "Eswatini", capital: "Mbabane", cities: ["Manzini"], region: .africa),
        .init(code: "ET", name: "Ethiopia", capital: "Addis Ababa", cities: ["Dire Dawa"], region: .africa),
        .init(code: "FJ", name: "Fiji", capital: "Suva", cities: ["Nadi"], region: .oceania),
        .init(code: "FI", name: "Finland", capital: "Helsinki", cities: ["Tampere", "Turku", "Espoo"], region: .europe),
        .init(code: "FR", name: "France", capital: "Paris", cities: ["Marseille", "Lyon", "Nice", "Bordeaux", "Toulouse"], region: .europe),
        .init(code: "GA", name: "Gabon", capital: "Libreville", region: .africa),
        .init(code: "GM", name: "Gambia", capital: "Banjul", region: .africa),
        .init(code: "GE", name: "Georgia", capital: "Tbilisi", cities: ["Batumi"], region: .asia),
        .init(code: "DE", name: "Germany", capital: "Berlin", cities: ["Munich", "Hamburg", "Frankfurt", "Cologne", "Stuttgart"], region: .europe),
        .init(code: "GH", name: "Ghana", capital: "Accra", cities: ["Kumasi"], region: .africa),
        .init(code: "GR", name: "Greece", capital: "Athens", cities: ["Thessaloniki", "Heraklion", "Patras"], region: .europe),
        .init(code: "GD", name: "Grenada", capital: "St. George's", region: .americas),
        .init(code: "GT", name: "Guatemala", capital: "Guatemala City", cities: ["Antigua"], region: .americas),
        .init(code: "GN", name: "Guinea", capital: "Conakry", region: .africa),
        .init(code: "GW", name: "Guinea-Bissau", capital: "Bissau", region: .africa),
        .init(code: "GY", name: "Guyana", capital: "Georgetown", region: .americas),
        .init(code: "HT", name: "Haiti", capital: "Port-au-Prince", cities: ["Cap-Haïtien"], region: .americas),
        .init(code: "HN", name: "Honduras", capital: "Tegucigalpa", cities: ["San Pedro Sula"], region: .americas),
        .init(code: "HU", name: "Hungary", capital: "Budapest", cities: ["Debrecen"], region: .europe),
        .init(code: "IS", name: "Iceland", capital: "Reykjavik", cities: ["Akureyri"], region: .europe),
        .init(code: "IN", name: "India", capital: "New Delhi", cities: ["Mumbai", "Bangalore", "Chennai", "Kolkata", "Hyderabad", "Jaipur"], region: .asia),
        .init(code: "ID", name: "Indonesia", capital: "Jakarta", cities: ["Surabaya", "Bali", "Bandung", "Yogyakarta"], region: .asia),
        .init(code: "IR", name: "Iran", capital: "Tehran", cities: ["Isfahan", "Shiraz", "Mashhad"], region: .asia),
        .init(code: "IQ", name: "Iraq", capital: "Baghdad", cities: ["Basra", "Mosul"], region: .asia),
        .init(code: "IE", name: "Ireland", capital: "Dublin", cities: ["Cork", "Galway"], region: .europe),
        .init(code: "IL", name: "Israel", capital: "Jerusalem", cities: ["Tel Aviv", "Haifa"], region: .asia),
        .init(code: "IT", name: "Italy", capital: "Rome", cities: ["Milan", "Florence", "Venice", "Naples", "Turin"], region: .europe),
        .init(code: "JM", name: "Jamaica", capital: "Kingston", cities: ["Montego Bay"], region: .americas),
        .init(code: "JP", name: "Japan", capital: "Tokyo", cities: ["Osaka", "Kyoto", "Yokohama", "Sapporo", "Nagoya"], region: .asia),
        .init(code: "JO", name: "Jordan", capital: "Amman", cities: ["Petra"], region: .asia),
        .init(code: "KZ", name: "Kazakhstan", capital: "Astana", cities: ["Almaty"], region: .asia),
        .init(code: "KE", name: "Kenya", capital: "Nairobi", cities: ["Mombasa"], region: .africa),
        .init(code: "KI", name: "Kiribati", capital: "Tarawa", region: .oceania),
        .init(code: "KP", name: "North Korea", capital: "Pyongyang", region: .asia),
        .init(code: "KR", name: "South Korea", capital: "Seoul", cities: ["Busan", "Incheon", "Daegu"], region: .asia),
        .init(code: "XK", name: "Kosovo", capital: "Pristina", cities: ["Prizren"], region: .europe),
        .init(code: "KW", name: "Kuwait", capital: "Kuwait City", region: .asia),
        .init(code: "KG", name: "Kyrgyzstan", capital: "Bishkek", cities: ["Osh"], region: .asia),
        .init(code: "LA", name: "Laos", capital: "Vientiane", cities: ["Luang Prabang"], region: .asia),
        .init(code: "LV", name: "Latvia", capital: "Riga", cities: ["Liepāja"], region: .europe),
        .init(code: "LB", name: "Lebanon", capital: "Beirut", cities: ["Byblos", "Tripoli"], region: .asia),
        .init(code: "LS", name: "Lesotho", capital: "Maseru", region: .africa),
        .init(code: "LR", name: "Liberia", capital: "Monrovia", region: .africa),
        .init(code: "LY", name: "Libya", capital: "Tripoli", cities: ["Benghazi"], region: .africa),
        .init(code: "LI", name: "Liechtenstein", capital: "Vaduz", region: .europe),
        .init(code: "LT", name: "Lithuania", capital: "Vilnius", cities: ["Kaunas"], region: .europe),
        .init(code: "LU", name: "Luxembourg", capital: "Luxembourg", region: .europe),
        .init(code: "MG", name: "Madagascar", capital: "Antananarivo", region: .africa),
        .init(code: "MW", name: "Malawi", capital: "Lilongwe", cities: ["Blantyre"], region: .africa),
        .init(code: "MY", name: "Malaysia", capital: "Kuala Lumpur", cities: ["Penang", "Johor Bahru", "Malacca"], region: .asia),
        .init(code: "MV", name: "Maldives", capital: "Malé", region: .asia),
        .init(code: "ML", name: "Mali", capital: "Bamako", cities: ["Timbuktu"], region: .africa),
        .init(code: "MT", name: "Malta", capital: "Valletta", region: .europe),
        .init(code: "MH", name: "Marshall Islands", capital: "Majuro", region: .oceania),
        .init(code: "MR", name: "Mauritania", capital: "Nouakchott", region: .africa),
        .init(code: "MU", name: "Mauritius", capital: "Port Louis", region: .africa),
        .init(code: "MX", name: "Mexico", capital: "Mexico City", cities: ["Guadalajara", "Monterrey", "Cancún", "Oaxaca"], region: .americas),
        .init(code: "FM", name: "Micronesia", capital: "Palikir", region: .oceania),
        .init(code: "MD", name: "Moldova", capital: "Chișinău", region: .europe),
        .init(code: "MC", name: "Monaco", capital: "Monaco", cities: ["Monte Carlo"], region: .europe),
        .init(code: "MN", name: "Mongolia", capital: "Ulaanbaatar", region: .asia),
        .init(code: "ME", name: "Montenegro", capital: "Podgorica", cities: ["Kotor", "Budva"], region: .europe),
        .init(code: "MA", name: "Morocco", capital: "Rabat", cities: ["Casablanca", "Marrakech", "Fez", "Tangier"], region: .africa),
        .init(code: "MZ", name: "Mozambique", capital: "Maputo", cities: ["Beira"], region: .africa),
        .init(code: "MM", name: "Myanmar", capital: "Naypyidaw", cities: ["Yangon", "Mandalay"], region: .asia),
        .init(code: "NA", name: "Namibia", capital: "Windhoek", cities: ["Swakopmund"], region: .africa),
        .init(code: "NR", name: "Nauru", capital: "Yaren", region: .oceania),
        .init(code: "NP", name: "Nepal", capital: "Kathmandu", cities: ["Pokhara", "Lalitpur"], region: .asia),
        .init(code: "NL", name: "Netherlands", capital: "Amsterdam", cities: ["Rotterdam", "The Hague", "Utrecht"], region: .europe),
        .init(code: "NZ", name: "New Zealand", capital: "Wellington", cities: ["Auckland", "Christchurch", "Queenstown"], region: .oceania),
        .init(code: "NI", name: "Nicaragua", capital: "Managua", cities: ["Granada"], region: .americas),
        .init(code: "NE", name: "Niger", capital: "Niamey", region: .africa),
        .init(code: "NG", name: "Nigeria", capital: "Abuja", cities: ["Lagos", "Ibadan", "Kano"], region: .africa),
        .init(code: "MK", name: "North Macedonia", capital: "Skopje", cities: ["Ohrid"], region: .europe),
        .init(code: "NO", name: "Norway", capital: "Oslo", cities: ["Bergen", "Trondheim", "Tromsø"], region: .europe),
        .init(code: "OM", name: "Oman", capital: "Muscat", cities: ["Salalah"], region: .asia),
        .init(code: "PK", name: "Pakistan", capital: "Islamabad", cities: ["Karachi", "Lahore", "Faisalabad"], region: .asia),
        .init(code: "PW", name: "Palau", capital: "Ngerulmud", region: .oceania),
        .init(code: "PS", name: "Palestine", capital: "East Jerusalem", cities: ["Ramallah", "Bethlehem", "Gaza"], region: .asia),
        .init(code: "PA", name: "Panama", capital: "Panama City", cities: ["Colón"], region: .americas),
        .init(code: "PG", name: "Papua New Guinea", capital: "Port Moresby", cities: ["Lae"], region: .oceania),
        .init(code: "PY", name: "Paraguay", capital: "Asunción", cities: ["Ciudad del Este"], region: .americas),
        .init(code: "PE", name: "Peru", capital: "Lima", cities: ["Cusco", "Arequipa", "Trujillo"], region: .americas),
        .init(code: "PH", name: "Philippines", capital: "Manila", cities: ["Cebu", "Davao", "Quezon City"], region: .asia),
        .init(code: "PL", name: "Poland", capital: "Warsaw", cities: ["Krakow", "Wrocław", "Gdańsk", "Poznań"], region: .europe),
        .init(code: "PT", name: "Portugal", capital: "Lisbon", cities: ["Porto", "Faro", "Coimbra"], region: .europe),
        .init(code: "QA", name: "Qatar", capital: "Doha", region: .asia),
        .init(code: "RO", name: "Romania", capital: "Bucharest", cities: ["Cluj-Napoca", "Brașov"], region: .europe),
        .init(code: "RU", name: "Russia", capital: "Moscow", cities: ["St. Petersburg", "Novosibirsk", "Sochi", "Kazan"], region: .europe),
        .init(code: "RW", name: "Rwanda", capital: "Kigali", region: .africa),
        .init(code: "KN", name: "Saint Kitts and Nevis", capital: "Basseterre", region: .americas),
        .init(code: "LC", name: "Saint Lucia", capital: "Castries", region: .americas),
        .init(code: "VC", name: "Saint Vincent and the Grenadines", capital: "Kingstown", region: .americas),
        .init(code: "WS", name: "Samoa", capital: "Apia", region: .oceania),
        .init(code: "SM", name: "San Marino", capital: "San Marino", region: .europe),
        .init(code: "ST", name: "São Tomé and Príncipe", capital: "São Tomé", region: .africa),
        .init(code: "SA", name: "Saudi Arabia", capital: "Riyadh", cities: ["Mecca", "Medina", "Jeddah"], region: .asia),
        .init(code: "SN", name: "Senegal", capital: "Dakar", region: .africa),
        .init(code: "RS", name: "Serbia", capital: "Belgrade", cities: ["Novi Sad", "Niš"], region: .europe),
        .init(code: "SC", name: "Seychelles", capital: "Victoria", region: .africa),
        .init(code: "SL", name: "Sierra Leone", capital: "Freetown", region: .africa),
        .init(code: "SG", name: "Singapore", capital: "Singapore", region: .asia),
        .init(code: "SK", name: "Slovakia", capital: "Bratislava", cities: ["Košice"], region: .europe),
        .init(code: "SI", name: "Slovenia", capital: "Ljubljana", cities: ["Maribor", "Bled"], region: .europe),
        .init(code: "SB", name: "Solomon Islands", capital: "Honiara", region: .oceania),
        .init(code: "SO", name: "Somalia", capital: "Mogadishu", region: .africa),
        .init(code: "ZA", name: "South Africa", capital: "Pretoria", cities: ["Cape Town", "Johannesburg", "Durban"], region: .africa),
        .init(code: "SS", name: "South Sudan", capital: "Juba", region: .africa),
        .init(code: "ES", name: "Spain", capital: "Madrid", cities: ["Barcelona", "Seville", "Valencia", "Granada", "Bilbao"], region: .europe),
        .init(code: "LK", name: "Sri Lanka", capital: "Colombo", cities: ["Kandy", "Galle"], region: .asia),
        .init(code: "SD", name: "Sudan", capital: "Khartoum", cities: ["Omdurman"], region: .africa),
        .init(code: "SR", name: "Suriname", capital: "Paramaribo", region: .americas),
        .init(code: "SE", name: "Sweden", capital: "Stockholm", cities: ["Gothenburg", "Malmö"], region: .europe),
        .init(code: "CH", name: "Switzerland", capital: "Bern", cities: ["Zurich", "Geneva", "Basel", "Lausanne"], region: .europe),
        .init(code: "SY", name: "Syria", capital: "Damascus", cities: ["Aleppo", "Palmyra"], region: .asia),
        .init(code: "TW", name: "Taiwan", capital: "Taipei", cities: ["Kaohsiung", "Tainan"], region: .asia),
        .init(code: "TJ", name: "Tajikistan", capital: "Dushanbe", region: .asia),
        .init(code: "TZ", name: "Tanzania", capital: "Dodoma", cities: ["Dar es Salaam", "Zanzibar"], region: .africa),
        .init(code: "TH", name: "Thailand", capital: "Bangkok", cities: ["Chiang Mai", "Phuket", "Pattaya"], region: .asia),
        .init(code: "TL", name: "Timor-Leste", capital: "Dili", region: .asia),
        .init(code: "TG", name: "Togo", capital: "Lomé", region: .africa),
        .init(code: "TO", name: "Tonga", capital: "Nuku'alofa", region: .oceania),
        .init(code: "TT", name: "Trinidad and Tobago", capital: "Port of Spain", region: .americas),
        .init(code: "TN", name: "Tunisia", capital: "Tunis", cities: ["Sousse", "Carthage"], region: .africa),
        .init(code: "TR", name: "Turkey", capital: "Ankara", cities: ["Istanbul", "Izmir", "Antalya", "Bursa"], region: .asia),
        .init(code: "TM", name: "Turkmenistan", capital: "Ashgabat", region: .asia),
        .init(code: "TV", name: "Tuvalu", capital: "Funafuti", region: .oceania),
        .init(code: "UG", name: "Uganda", capital: "Kampala", cities: ["Entebbe"], region: .africa),
        .init(code: "UA", name: "Ukraine", capital: "Kyiv", cities: ["Lviv", "Odesa", "Kharkiv"], region: .europe),
        .init(code: "AE", name: "United Arab Emirates", capital: "Abu Dhabi", cities: ["Dubai", "Sharjah"], region: .asia),
        .init(code: "GB", name: "United Kingdom", capital: "London", cities: ["Manchester", "Edinburgh", "Glasgow", "Liverpool", "Birmingham"], region: .europe),
        .init(code: "US", name: "United States", capital: "Washington", cities: ["New York", "Los Angeles", "Chicago", "Miami", "San Francisco"], region: .americas),
        .init(code: "UY", name: "Uruguay", capital: "Montevideo", cities: ["Punta del Este"], region: .americas),
        .init(code: "UZ", name: "Uzbekistan", capital: "Tashkent", cities: ["Samarkand", "Bukhara"], region: .asia),
        .init(code: "VU", name: "Vanuatu", capital: "Port Vila", region: .oceania),
        .init(code: "VA", name: "Vatican City", capital: "Vatican City", region: .europe),
        .init(code: "VE", name: "Venezuela", capital: "Caracas", cities: ["Maracaibo", "Valencia"], region: .americas),
        .init(code: "VN", name: "Vietnam", capital: "Hanoi", cities: ["Ho Chi Minh City", "Da Nang", "Hoi An"], region: .asia),
        .init(code: "YE", name: "Yemen", capital: "Sana'a", cities: ["Aden"], region: .asia),
        .init(code: "ZM", name: "Zambia", capital: "Lusaka", region: .africa),
        .init(code: "ZW", name: "Zimbabwe", capital: "Harare", cities: ["Bulawayo", "Victoria Falls"], region: .africa),
    ]

    public static let byCode: [String: Country] = {
        Dictionary(uniqueKeysWithValues: all.map { ($0.code, $0) })
    }()

    public static let totalCount: Int = all.count

    /// Returns all place names (countries, capitals, major cities) for the
    /// given set of country codes. Used by the typographic backdrop.
    public static func placeNames(forCodes codes: Set<String>) -> [String] {
        codes.compactMap { byCode[$0] }
            .flatMap(\.allPlaceNames)
    }
}
