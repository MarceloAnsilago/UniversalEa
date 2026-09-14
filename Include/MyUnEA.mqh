#ifndef MY_UN_EA_MQH
#define MY_UN_EA_MQH

#include "Indicators/MyIndicatorFactory.mqh"

// Classe responsavel pela futura logica do Expert Advisor.
class MyUnEA
  {
private:
   //--- Atributos: configuracoes e parametros da estrategia.
   // Cada instancia representa um setup configurado na interface.
   string m_name;                           // Nome do setup.
   string m_set_id;                         // Identidade do arquivo de configuracao.
   long m_magic;                           // Magic Number do setup.
   ENUM_GUI_SETUP_MARKET m_market;          // Forex ou B3.
   ENUM_TIMEFRAMES m_timeframe;             // Periodo de operacao.
   ENUM_GUI_SETUP_DIRECTION m_direction;    // Compra e venda, somente compra ou somente venda.
   ENUM_GUI_SETUP_TRADE_MODE m_trade_mode;  // Day trade ou swing trade.
   double m_lot;                           // Volume por operacao.

   //--- Horarios: minutos desde 00:00, no horario do servidor.
   int m_entry_start;                       // Inicio permitido para entradas.
   int m_entry_end;                         // Fim permitido para entradas.
   bool m_close_enabled;                    // Encerramento por horario habilitado.
   int m_close_time;                        // Horario de encerramento.

   //--- Regras de entrada e alvos.
   ENUM_GUI_ORDER_MODE m_order_mode;        // Ordem a mercado ou pendente.
   ENUM_GUI_CANDLE_FILTER m_candle_filter;  // Desativado, candle de alta ou de baixa.
   ENUM_GUI_TARGET_UNIT m_target_unit;      // Pontos ou percentual para os alvos.
   double m_stop_loss;                      // Zero desativa o stop loss.
   double m_take_profit;                    // Zero desativa o take profit.

   //--- Breakeven: modo 0 = desativado, 1 = pontos, 2 = percentual.
   int m_breakeven_mode;
   double m_breakeven_trigger;              // Ativacao (management.values[0]).
   double m_breakeven_offset;               // Protecao (management.values[1]).

   //--- Trailing stop: valores na unidade selecionada pelo modo.
   int m_trailing_mode;                     // 0 = desativado, 1 = pontos, 2 = percentual.
   double m_trailing_trigger;               // Ativacao (management.values[2]).
   double m_trailing_distance;              // Distancia (management.values[3]).
   double m_trailing_step;                  // Passo (management.values[4]).

   //--- Stop movel: valores na unidade selecionada pelo modo.
   int m_moving_stop_mode;                  // 0 = desativado, 1 = pontos, 2 = percentual.
   double m_moving_stop_trigger;            // Ativacao (management.values[5]).
   double m_moving_stop_distance;           // Distancia (management.values[6]).
   double m_moving_stop_step;               // Passo (management.values[7]).

   //--- Atributos: estado interno e controle de execucao.
   // Limites de volume do ativo usados pela interface para validar o lote.
   double m_volume_min;
   double m_volume_max;
   double m_volume_step;

   //--- Atributos: indicadores e recursos utilizados pelo EA.
   // Slots possuem objetos polimorficos; NULL representa um slot desativado.
   MyIndicator *m_indicators[4];

   //--- Metodos auxiliares: validacoes e preparacao dos dados.

   //--- Metodos da estrategia: avaliacao dos sinais de entrada e saida.

   //--- Metodos de gestao: risco, ordens e posicoes.

protected:
   //--- Atributos e metodos destinados a futuras classes derivadas.

public:
   // Interface publica: metodos acessiveis pelo programa que utiliza a classe.

   //--- Construtor e destrutor.
   // Construtor: executado automaticamente ao criar uma instancia de MyUnEA.
   // Inicializa os atributos com os valores padrao da interface, incluindo
   // horarios, regras, gestao desativada e os quatro slots vazios.
   // Nao recebe parametros e nao inicia operacoes de negociacao.
   MyUnEA()
     {
      // Padroes locais da interface; a configuracao aplicada sera carregada depois.
      // Nao reserva Magic Number nem consulta o ativo durante a construcao.
      m_name="Meu setup";
      m_set_id="";
      m_magic=1;
      m_market=GUI_SETUP_FOREX;
      m_timeframe=PERIOD_M1;
      m_direction=GUI_SETUP_BUY_SELL;
      m_trade_mode=GUI_SETUP_DAY_TRADE;
      m_lot=0.01;

      // Janela de entradas de 00:00 a 23:55, com encerramento desativado.
      m_entry_start=0;
      m_entry_end=1435;
      m_close_enabled=false;
      m_close_time=1435;

      m_order_mode=GUI_ORDER_MARKET;
      m_candle_filter=GUI_CANDLE_DISABLED;
      m_target_unit=GUI_TARGET_POINTS;
      m_stop_loss=0.0;
      m_take_profit=0.0;

      // As tres modalidades de gestao iniciam desativadas.
      m_breakeven_mode=0;
      m_breakeven_trigger=0.0;
      m_breakeven_offset=0.0;
      m_trailing_mode=0;
      m_trailing_trigger=0.0;
      m_trailing_distance=0.0;
      m_trailing_step=0.0;
      m_moving_stop_mode=0;
      m_moving_stop_trigger=0.0;
      m_moving_stop_distance=0.0;
      m_moving_stop_step=0.0;

      // Padroes de CGuiSetupState::Reset; substituir pelos limites do ativo
      // ao carregar a configuracao, antes de permitir qualquer operacao.
      m_volume_min=0.01;
      m_volume_max=100.0;
      m_volume_step=0.01;

      // Cada slot recebera somente o objeto do tipo selecionado.
      for(int i=0;i<4;i++) m_indicators[i]=NULL;
     }

   // Destrutor: executado automaticamente ao destruir a instancia de MyUnEA.
   // Libera os objetos dos slots e seus recursos pelo destrutor virtual.
   ~MyUnEA()
     {
      for(int i=0;i<4;i++)
        {
         if(m_indicators[i]!=NULL) delete m_indicators[i];
         m_indicators[i]=NULL;
        }
     }

   //--- Metodos de ciclo de vida: inicializacao e finalizacao.
   // Futuros metodos para preparar o EA e liberar seus recursos ao finalizar.

   //--- Metodos de processamento: ticks e demais eventos do EA.
   // Futuros metodos chamados pelo programa principal ao receber eventos.

   //--- Metodos de configuracao e consulta do estado.
   // Configura um slot (0 a 3) sem criar handles ou iniciar negociacao.
   // Parametros invalidos preservam o objeto anterior; NONE desativa o slot.
   bool ConfigureIndicator(const int slot,const IndicatorConfig &config,string &error)
     {
      error="";
      if(slot<0 || slot>=4) { error="Slot de indicador invalido."; return false; }
      MyIndicator *candidate=MyIndicatorFactory::Create(config,error);
      if(error!="") return false;
      if(m_indicators[slot]!=NULL) delete m_indicators[slot];
      m_indicators[slot]=candidate;
      return true;
     }

   //--- Metodos de integracao com a interface grafica.
   // Futuros metodos para receber as configuracoes escolhidas pelo usuario.
  };

#endif // MY_UN_EA_MQH
