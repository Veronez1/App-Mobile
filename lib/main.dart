import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AppPaisesMundo());
}

class AppPaisesMundo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paises do Mundo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.dark, // Modo escuro
      ),
      home: TelaDeAbertura(),
    );
  }
}

// Tela de TelaDeAbertura exibida no início
class TelaDeAbertura extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Paises do Mundo',
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
                    builder: (context) => TelaListaPaises(),
                  ),
                );
              },
              child: Text(
                'Iniciar',
                style: TextStyle(fontSize: 24),
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

// Classe que representa um país
class Pais {
  String nome;
  String capital;
  String regiao;
  String subRegiao;
  String populacao;
  String flagUrl;
  List<String> idioma;
  List<String> moeda;
  String brasao;
  List<String> fusoHorario;

  Pais({
    required this.nome,
    required this.capital,
    required this.regiao,
    required this.subRegiao,
    required this.populacao,
    required this.flagUrl,
    required this.idioma,
    required this.moeda,
    required this.brasao,
    required this.fusoHorario,
  });
}

// Tela que exibe a lista de países
class TelaListaPaises extends StatefulWidget {
  @override
  _TelaListaPaisesState createState() => _TelaListaPaisesState();
}

class _TelaListaPaisesState extends State<TelaListaPaises> {
  late Future<List<Pais>> _paisDados;

  @override
  void initState() {
    super.initState();
    WebView.platform = SurfaceAndroidWebView();
    _paisDados = _getPaisDados();
  }

  // Função assíncrona para buscar os dados dos países
  // A implementação da lógica de consumo da REST API está presente no método _getPaisDados,
  // onde são realizadas requisições HTTP para obter os dados dos países.
  Future<List<Pais>> _getPaisDados() async {
    final response =
        await http.get(Uri.parse('https://restcountries.com/v3.1/all'));
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(utf8.decode(response.bodyBytes));

      List<Pais> paises = [];
      for (var paisDado in jsonData) {
        List<String> idioma = [];
        if (paisDado['languages'] != null) {
          for (var language in paisDado['languages'].values) {
            idioma.add(language.toString());
          }
        }

        List<String> moeda = [];
        if (paisDado['currencies'] != null) {
          paisDado['currencies'].forEach((key, value) {
            String nomeMoeda = value['name'];
            String simboloMoeda = value['symbol'];
            String currency = '$nomeMoeda ($simboloMoeda)';
            moeda.add(currency);
          });
        }

        List<String> fusoHorario = [];
        if (paisDado['timezones'] != null) {
          for (var timezone in paisDado['timezones']) {
            fusoHorario.add(timezone.toString());
          }
        }
        String brasao = '';
        if (paisDado['flags'] != null && paisDado['flags']['png'] != null) {
          brasao = paisDado['flags']['png'];
        }

        String populacao = '';
        if (paisDado['population'] != null) {
          int populationCount = paisDado['population'];
          populacao = formataPopulacao(populationCount);
        }

        Pais pais = Pais(
          nome: paisDado['name']['common'] ?? 'N/A',
          capital: paisDado['capital'] != null ? paisDado['capital'][0] : 'N/A',
          regiao: paisDado['region'] ?? 'N/A',
          subRegiao: paisDado['subregion'] ?? 'N/A',
          populacao: populacao,
          flagUrl: brasao,
          idioma: idioma,
          moeda: moeda,
          brasao: brasao,
          fusoHorario: fusoHorario,
        );

        paises.add(pais);
      }

      // Ordenar países em ordem alfabética
      paises.sort((a, b) => a.nome.compareTo(b.nome));

      return paises;
    } else {
      throw Exception('Falha ao buscar os dados dos países');
    }
  }

  // Função para formatar a população do país
  String formataPopulacao(int populacao) {
    if (populacao < 1000) {
      return populacao.toString();
    } else if (populacao < 1000000) {
      double populationInK = populacao / 1000;
      return '${populationInK.toStringAsFixed(1)} Mil';
    } else if (populacao < 1000000000) {
      double populationInM = populacao / 1000000;
      return '${populationInM.toStringAsFixed(1)} Mi';
    } else {
      double populationInB = populacao / 1000000000;
      return '${populationInB.toStringAsFixed(1)} Bi';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paises do Mundo'),
      ),
      body: FutureBuilder<List<Pais>>(
        future: _paisDados,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // Agrupar países por região e sub-região
            Map<String, Map<String, List<Pais>>> groupedCountries = {};
            snapshot.data!.forEach((pais) {
              if (groupedCountries.containsKey(pais.regiao)) {
                Map<String, List<Pais>> subRegions =
                    groupedCountries[pais.regiao]!;
                if (subRegions.containsKey(pais.subRegiao)) {
                  subRegions[pais.subRegiao]!.add(pais);
                } else {
                  subRegions[pais.subRegiao] = [pais];
                }
              } else {
                groupedCountries[pais.regiao] = {
                  pais.subRegiao: [pais]
                };
              }
            });

            return ListView.builder(
              itemCount: groupedCountries.length,
              itemBuilder: (context, index) {
                String regiao = groupedCountries.keys.elementAt(index);
                Map<String, List<Pais>> subRegions = groupedCountries[regiao]!;
                List<String> subRegionNames = subRegions.keys.toList();
                subRegionNames.sort();

                return ExpansionTile(
                  title: Text(
                    regiao,
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
                                .map((pais) => ListTile(
                                      leading: Container(
                                        width: 48,
                                        height: 32,
                                        child: Image.network(
                                          pais.flagUrl,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      title: Text(
                                        pais.nome,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Capital: ${pais.capital}'),
                                          SizedBox(height: 4),
                                          Text('População: ${pais.populacao}'),
                                          SizedBox(height: 4),
                                        ],
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CountryDetailsScreen(
                                              pais: pais,
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
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class CountryDetailsScreen extends StatelessWidget {
  final Pais pais;

  const CountryDetailsScreen({required this.pais});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pais.nome),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pais.flagUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.network(
                      pais.flagUrl,
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
                    'Capital: ${pais.capital}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'População: ${pais.populacao}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Região: ${pais.regiao}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sub-região: ${pais.subRegiao}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            if (pais.idioma.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Idiomas',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: pais.idioma.map((language) {
                        return Text(
                          language,
                          style: TextStyle(fontSize: 16),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            if (pais.moeda.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Moedas',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: pais.moeda.map((currency) {
                        return Text(
                          currency,
                          style: TextStyle(fontSize: 16),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            if (pais.fusoHorario.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fusos Horários',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: pais.fusoHorario.map((timezone) {
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
