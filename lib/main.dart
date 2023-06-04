import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(RestCountriesApp());
}

class RestCountriesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paises do mundo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.dark, // Dark mode
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Paises do mundo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CountryListScreen(),
                  ),
                );
              },
              child: Text(
                'Iniciar',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                primary: Colors.white,
                onPrimary: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Country {
  String name;
  String capital;
  String region;
  String subregion;
  String population;
  String flagUrl;
  List<String> languages;
  List<String> currencies;
  String coatOfArmsUrl;
  List<String> timezones;

  Country({
    required this.name,
    required this.capital,
    required this.region,
    required this.subregion,
    required this.population,
    required this.flagUrl,
    required this.languages,
    required this.currencies,
    required this.coatOfArmsUrl,
    required this.timezones,
  });
}

class CountryListScreen extends StatefulWidget {
  @override
  _CountryListScreenState createState() => _CountryListScreenState();
}

class _CountryListScreenState extends State<CountryListScreen> {
  late Future<List<Country>> _countryData;

  @override
  void initState() {
    super.initState();
    WebView.platform = SurfaceAndroidWebView();
    _countryData = _fetchCountryData();
  }

  Future<List<Country>> _fetchCountryData() async {
    final response =
        await http.get(Uri.parse('https://restcountries.com/v3.1/all'));
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(utf8.decode(response.bodyBytes));

      List<Country> countries = [];
      for (var countryData in jsonData) {
        List<String> languages = [];
        if (countryData['languages'] != null) {
          for (var language in countryData['languages'].values) {
            languages.add(language.toString());
          }
        }

        List<String> currencies = [];
        if (countryData['currencies'] != null) {
          countryData['currencies'].forEach((key, value) {
            String currencyName = value['name'];
            String currencySymbol = value['symbol'];
            String currency = '$currencyName ($currencySymbol)';
            currencies.add(currency);
          });
        }

        List<String> timezones = [];
        if (countryData['timezones'] != null) {
          for (var timezone in countryData['timezones']) {
            timezones.add(timezone.toString());
          }
        }
        String coatOfArmsUrl = '';
        if (countryData['flags'] != null &&
            countryData['flags']['png'] != null) {
          coatOfArmsUrl = countryData['flags']['png'];
        }

        String population = '';
        if (countryData['population'] != null) {
          int populationCount = countryData['population'];
          population = formatPopulation(populationCount);
        }

        Country country = Country(
          name: countryData['name']['common'] ?? 'N/A',
          capital: countryData['capital'] != null
              ? countryData['capital'][0]
              : 'N/A',
          region: countryData['region'] ?? 'N/A',
          subregion: countryData['subregion'] ?? 'N/A',
          population: population,
          flagUrl: coatOfArmsUrl,
          languages: languages,
          currencies: currencies,
          coatOfArmsUrl: coatOfArmsUrl,
          timezones: timezones,
        );

        countries.add(country);
      }

      // Sort countries alphabetically
      countries.sort((a, b) => a.name.compareTo(b.name));

      return countries;
    } else {
      throw Exception('Failed to fetch country data');
    }
  }

  String formatPopulation(int population) {
    if (population < 1000) {
      return population.toString();
    } else if (population < 1000000) {
      double populationInK = population / 1000;
      return '${populationInK.toStringAsFixed(1)}K';
    } else if (population < 1000000000) {
      double populationInM = population / 1000000;
      return '${populationInM.toStringAsFixed(1)}M';
    } else {
      double populationInB = population / 1000000000;
      return '${populationInB.toStringAsFixed(1)}B';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paises do mundo'),
      ),
      body: FutureBuilder<List<Country>>(
        future: _countryData,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // Group countries by region and sub-region
            Map<String, Map<String, List<Country>>> groupedCountries = {};
            snapshot.data!.forEach((country) {
              if (groupedCountries.containsKey(country.region)) {
                Map<String, List<Country>> subRegions =
                    groupedCountries[country.region]!;
                if (subRegions.containsKey(country.subregion)) {
                  subRegions[country.subregion]!.add(country);
                } else {
                  subRegions[country.subregion] = [country];
                }
              } else {
                groupedCountries[country.region] = {
                  country.subregion: [country]
                };
              }
            });

            return ListView.builder(
              itemCount: groupedCountries.length,
              itemBuilder: (context, index) {
                String region = groupedCountries.keys.elementAt(index);
                Map<String, List<Country>> subRegions =
                    groupedCountries[region]!;
                List<String> subRegionNames = subRegions.keys.toList();
                subRegionNames.sort();

                return ExpansionTile(
                  title: Text(
                    region,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  children: subRegionNames
                      .map((subRegionName) => ExpansionTile(
                            title: Text(
                              subRegionName,
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                            children: subRegions[subRegionName]!
                                .map((country) => ListTile(
                                      leading: Container(
                                        width: 48,
                                        height: 32,
                                        child: Image.network(
                                          country.flagUrl,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      title: Text(
                                        country.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Capital: ${country.capital}'),
                                          SizedBox(height: 4),
                                          Text(
                                              'Population: ${country.population}'),
                                          SizedBox(height: 4),
                                        ],
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CountryDetailsScreen(
                                              country: country,
                                            ),
                                          ),
                                        );
                                      },
                                    ))
                                .toList(),
                          ))
                      .toList(),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class CountryDetailsScreen extends StatelessWidget {
  final Country country;

  const CountryDetailsScreen({required this.country});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(country.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (country.flagUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.network(
                      country.flagUrl,
                      fit: BoxFit.cover,
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Capital: ${country.capital}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Population: ${country.population}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Region: ${country.region}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Subregion: ${country.subregion}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            if (country.languages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Languages',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: country.languages.map((language) {
                        return Text(
                          language,
                          style: TextStyle(fontSize: 16),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            if (country.currencies.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Currencies',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: country.currencies.map((currency) {
                        return Text(
                          currency,
                          style: TextStyle(fontSize: 16),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            if (country.timezones.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Timezones',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: country.timezones.map((timezone) {
                        return Text(
                          timezone,
                          style: TextStyle(fontSize: 16),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
