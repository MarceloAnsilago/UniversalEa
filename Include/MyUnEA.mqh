#ifndef MY_UN_EA_MQH
#define MY_UN_EA_MQH

#include "Indicators/MyIndicatorFactory.mqh"

// Classe responsavel pela futura logica do Expert Advisor.
class MyUnEA
  {
private:
   string m_symbol;                         // Ativo usado pelos indicadores.
   bool m_initialized;                      // Recursos inicializados com sucesso.
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
   MqlTick m_latest_price;                  // Última cotação válida recebida neste processamento.
   MqlRates m_rates[];                      // Velas: [0] atual, [1] última fechada, [2] anterior.
   datetime m_previous_bar_time;            // Abertura da última vela reconhecida pelo EA.
   // Limites de volume do ativo usados pela interface para validar o lote.
   double m_volume_min;
   double m_volume_max;
   double m_volume_step;

   //--- Atributos: indicadores e recursos utilizados pelo EA.
   // Slots possuem objetos polimorficos; NULL representa um slot desativado.
   MyIndicator *m_indicators[4];

   //--- Metodos auxiliares: validacoes e preparacao dos dados.
   // Detecta e registra uma nova barra usando seu horario de abertura.
   // Deve ser chamado somente depois de obter todos os dados necessarios.
   bool IsNewBar(const datetime current_bar_time)
     {
      //--- 1. Ignorar horarios invalidos, a mesma barra e historico atrasado.
      if(current_bar_time<=0 || current_bar_time<=m_previous_bar_time)
         return false;

      //--- 2. Guardar a abertura para nao processar esta barra novamente.
      // Na primeira leitura, m_previous_bar_time e zero: a barra e aceita.
      // doDeinit zera esse controle ao reiniciar ou trocar a configuracao.
      m_previous_bar_time=current_bar_time;
      return true;
     }

   // Confere limites e relacoes dos inputs antes de criar qualquer handle.
   bool ValidateConfiguration(string &error)
     {
      error="";
      if(StringLen(m_name)>48 || m_magic<1 || m_magic>2147483647)
        { error="Nome: até 48 caracteres. Magic: 1 a 2147483647."; return false; }
      if((int)m_market<0 || (int)m_market>1 || (int)m_direction<0 || (int)m_direction>2 ||
         (int)m_trade_mode<0 || (int)m_trade_mode>1)
        { error="Mercado, direção ou modalidade inválidos."; return false; }
      if(PeriodSeconds(m_timeframe)<=0)
        { error="Período da estratégia inválido."; return false; }
      if(!MathIsValidNumber(m_lot) || m_lot<=0 || m_lot<m_volume_min-m_volume_step*1e-8 ||
         m_lot>m_volume_max+m_volume_step*1e-8)
        { error="Lote fora dos limites permitidos pelo ativo."; return false; }
      double units=m_lot/m_volume_step;
      double tolerance=MathMin(1e-5,MathMax(1e-8,8.0*2.2204460492503131e-16*MathAbs(units)));
      if(!MathIsValidNumber(units) || MathAbs(units-MathRound(units))>tolerance)
        { error="Lote deve respeitar o passo de volume do ativo."; return false; }
      if(!ValidTime(m_entry_start) || !ValidTime(m_entry_end) || !ValidTime(m_close_time) ||
         m_entry_start==m_entry_end)
        { error="Horários: 00:00 a 23:55 em passos de 5 minutos; início e fim diferentes."; return false; }
      if(m_close_enabled && (m_close_time-m_entry_start+1440)%1440<(m_entry_end-m_entry_start+1440)%1440)
        { error="Encerramento deve ocorrer no fim das entradas ou depois."; return false; }
      if((int)m_order_mode<0 || (int)m_order_mode>1 || (int)m_candle_filter<0 ||
         (int)m_candle_filter>2 || (int)m_target_unit<0 || (int)m_target_unit>1 ||
         !ValidAmount(m_stop_loss) || !ValidAmount(m_take_profit))
        { error="Confira o tipo de ordem, filtro, unidade e alvos."; return false; }
      if(m_breakeven_mode<0 || m_breakeven_mode>2 || !ValidAmount(m_breakeven_trigger) ||
         !ValidAmount(m_breakeven_offset) ||
         (m_breakeven_mode!=0 && (m_breakeven_trigger<=0 || m_breakeven_offset>=m_breakeven_trigger)))
        { error="Breakeven: ativação positiva e proteção menor que a ativação."; return false; }
      if(!ValidTrailing(m_trailing_mode,m_trailing_trigger,m_trailing_distance,m_trailing_step) ||
         !ValidTrailing(m_moving_stop_mode,m_moving_stop_trigger,m_moving_stop_distance,m_moving_stop_step))
        { error="Trailing e stop móvel: modo válido e valores positivos quando habilitados."; return false; }
      return true;
     }
   bool ValidTime(const int value) { return value>=0 && value<=1435 && value%5==0; }
   bool ValidAmount(const double value) { return MathIsValidNumber(value) && value>=0 && value<=100000000; }
   bool ValidTrailing(const int mode,const double trigger,const double distance,const double step)
     {
      return mode>=0 && mode<=2 && ValidAmount(trigger) && ValidAmount(distance) && ValidAmount(step) &&
             (mode==0 || (trigger>0 && distance>0 && step>0));
     }

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
      m_symbol="";
      m_initialized=false;
      ZeroMemory(m_latest_price);
      m_previous_bar_time=0;
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
   // Libera handles, preservando objetos e parametros para uma nova inicializacao.
   void doDeinit()
     {
      for(int i=0;i<4;i++) if(m_indicators[i]!=NULL) m_indicators[i].Release();
      m_initialized=false;
      ZeroMemory(m_latest_price);
      ArrayFree(m_rates);
      m_previous_bar_time=0;
     }

   // Consulta o ativo, valida os parametros e inicializa os indicadores ativos.
   // Retorna um codigo INIT_* e informa a causa quando houver falha.
   int doInit(string &error)
     {
      doDeinit(); error="";
      if(m_symbol=="" || !SymbolSelect(m_symbol,true))
        { error="Não foi possível selecionar o ativo."; return INIT_FAILED; }
      if(!SymbolInfoDouble(m_symbol,SYMBOL_VOLUME_MIN,m_volume_min) ||
         !SymbolInfoDouble(m_symbol,SYMBOL_VOLUME_MAX,m_volume_max) ||
         !SymbolInfoDouble(m_symbol,SYMBOL_VOLUME_STEP,m_volume_step) ||
         !MathIsValidNumber(m_volume_min) || !MathIsValidNumber(m_volume_max) ||
         !MathIsValidNumber(m_volume_step) || m_volume_min<=0 ||
         m_volume_max<m_volume_min || m_volume_step<=0)
        { error="Limites de volume do ativo indisponíveis."; return INIT_FAILED; }
      if(!ValidateConfiguration(error)) return INIT_PARAMETERS_INCORRECT;
      for(int i=0;i<4;i++)
         if(m_indicators[i]!=NULL)
           {
            ResetLastError();
            if(!m_indicators[i].Initialize(m_symbol,m_timeframe))
              {
               int code=GetLastError();
               error=StringFormat("Falha ao inicializar Indicador %d. Erro do terminal: %d.",i+1,code);
               doDeinit(); return INIT_FAILED;
              }
           }
      m_initialized=true;
      return INIT_SUCCEEDED;
     }

   // Permite consultar se a etapa de inicializacao foi concluida.
   bool IsInitialized() { return m_initialized; }

   //--- Metodos de processamento: ticks e demais eventos do EA.
   // Prepara a cotação e as velas seguindo o fluxo do OnTick.
   // Retorna true uma vez por nova vela; false indica espera ou falha.
   // Em caso de falha, error explica o motivo. Na mesma vela, error fica vazio.
   bool doTick(string &error)
     {
      error="";

      //--- 1. Processar somente depois de uma inicialização bem-sucedida.
      if(!m_initialized)
        { error="MyUnEA ainda não foi inicializada."; return false; }

      // Descartar o retrato anterior para não reutilizar dados após uma falha.
      ZeroMemory(m_latest_price);
      ArrayFree(m_rates);

      //--- 2. Exigir pelo menos 60 velas, como no exemplo de referência.
      // Este é o mínimo do fluxo; a prontidão dos buffers será verificada
      // na futura leitura dos indicadores, que podem exigir mais histórico.
      int bars=Bars(m_symbol,m_timeframe);
      if(bars<60)
        {
         // Solicitar o histórico também inicia seu carregamento, se necessário.
         // Não bloquear o EA: tentar novamente quando chegar outro tick.
         MqlRates history[];
         if(CopyRates(m_symbol,m_timeframe,0,60,history)!=60)
           { error="Aguardando pelo menos 60 velas no período configurado."; return false; }
        }

      //--- 3. Obter os preços e o horário da última cotação do ativo.
      MqlTick latest_price;
      ResetLastError();
      if(!SymbolInfoTick(m_symbol,latest_price))
        {
         error=StringFormat("Erro ao obter a última cotação: %d.",GetLastError());
         return false;
        }
      if(latest_price.time<=0)
        { error="Aguardando uma cotação válida do ativo."; return false; }

      //--- 4. Organizar as velas como série temporal e copiar as três últimas.
      // Índice 0 = vela em formação; índices 1 e 2 = velas já fechadas.
      // Exigir as três: uma cópia parcial ainda não permite continuar.
      MqlRates rates[];
      ArraySetAsSeries(rates,true);
      ResetLastError();
      if(CopyRates(m_symbol,m_timeframe,0,3,rates)!=3)
        {
         error=StringFormat("Aguardando a cópia das três últimas velas. Erro: %d.",GetLastError());
         return false;
        }
      if(rates[0].time<=0 || rates[1].time>=rates[0].time || rates[2].time>=rates[1].time)
        { error="Histórico de velas ainda não está pronto."; return false; }

      //--- 5. Guardar o retrato válido para os próximos métodos da estratégia.
      if(ArrayResize(m_rates,3)!=3)
        { error="Não foi possível reservar memória para as velas."; return false; }
      ArraySetAsSeries(m_rates,true);
      for(int i=0;i<3;i++) m_rates[i]=rates[i];
      m_latest_price=latest_price;

      // A futura gestão de posições a cada tick deve ficar antes deste filtro.
      // Assim, breakeven e trailing não dependerão da abertura de uma vela.

      //--- 6. Liberar a etapa de novas entradas apenas uma vez por barra.
      // A abertura vem da vela [0] do periodo escolhido nos inputs.
      // IsNewBar compara e registra o horario nesta instancia da classe.
      // Futuras leituras de buffers que possam falhar devem preceder esta
      // chamada, permitindo tentar novamente sem consumir a nova barra.
      return IsNewBar(m_rates[0].time);
     }

   //--- Metodos de configuracao e consulta do estado.
   // Define o ativo antes de inicializar os indicadores.
   void setSymbol(const string value)
     { doDeinit(); m_symbol=value; }

   // Define o timeframe; PERIOD_CURRENT usa o periodo do grafico.
   void setPeriod(const ENUM_TIMEFRAMES value)
     { doDeinit(); m_timeframe=(value==PERIOD_CURRENT ? (ENUM_TIMEFRAMES)_Period : value); }

   // Define o identificador das futuras operacoes.
   void setMagic(const long value)
     { doDeinit(); m_magic=value; }

   // Define o volume solicitado, validado contra os limites do ativo em doInit.
   void setLOTS(const double value)
     { doDeinit(); m_lot=value; }

   // Define o nome, mercado, direcao e modalidade do setup.
   void setSetup(const string name,const ENUM_GUI_SETUP_MARKET market,const ENUM_GUI_SETUP_DIRECTION direction,const ENUM_GUI_SETUP_TRADE_MODE mode)
     { doDeinit(); m_name=name; m_market=market; m_direction=direction; m_trade_mode=mode; }

   // Define horarios em minutos desde 00:00, no horario do servidor.
   void setSchedule(const int start,const int end,const bool close_enabled,const int close_time)
     { doDeinit(); m_entry_start=start; m_entry_end=end; m_close_enabled=close_enabled; m_close_time=close_time; }

   // Define regras e alvos na unidade escolhida; pontos nao sao convertidos em pips.
   void setRules(const ENUM_GUI_ORDER_MODE order,const ENUM_GUI_CANDLE_FILTER candle,const ENUM_GUI_TARGET_UNIT unit,const double stop,const double take)
     { doDeinit(); m_order_mode=order; m_candle_filter=candle; m_target_unit=unit; m_stop_loss=stop; m_take_profit=take; }

   // Define o breakeven: modo 0 desativa, 1 usa pontos e 2 usa percentual.
   void setBreakeven(const int mode,const double trigger,const double offset)
     { doDeinit(); m_breakeven_mode=mode; m_breakeven_trigger=trigger; m_breakeven_offset=offset; }

   // Define ativacao, distancia e passo do trailing stop.
   void setTrailing(const int mode,const double trigger,const double distance,const double step)
     { doDeinit(); m_trailing_mode=mode; m_trailing_trigger=trigger; m_trailing_distance=distance; m_trailing_step=step; }

   // Define ativacao, distancia e passo do stop movel.
   void setMovingStop(const int mode,const double trigger,const double distance,const double step)
     { doDeinit(); m_moving_stop_mode=mode; m_moving_stop_trigger=trigger; m_moving_stop_distance=distance; m_moving_stop_step=step; }
   // Configura um slot (0 a 3) sem criar handles ou iniciar negociacao.
   // Parametros invalidos preservam o objeto anterior; NONE desativa o slot.
   bool ConfigureIndicator(const int slot,const IndicatorConfig &config,string &error)
     {
      error="";
      if(slot<0 || slot>=4) { error="Slot de indicador invalido."; return false; }
      MyIndicator *candidate=MyIndicatorFactory::Create(config,error);
      if(error!="") return false;
      doDeinit();
      if(m_indicators[slot]!=NULL) delete m_indicators[slot];
      m_indicators[slot]=candidate;
      return true;
     }

   //--- Metodos de integracao com a interface grafica.
   // Futuros metodos para receber as configuracoes escolhidas pelo usuario.
  };

#endif // MY_UN_EA_MQH
