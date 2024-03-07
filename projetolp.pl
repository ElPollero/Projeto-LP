% 106930, Andre Daniel da Silva Bento
:- set_prolog_flag(answer_write_options,[max_depth(0)]). % para listas completas
:- ['dados.pl'], ['keywords.pl']. % ficheiros a importar.

%3.1

%---------------------------------------------------------------------
% eventosSemSalas(EventosSemSala): EventosSemSala e' a lista de IDs dos
% eventos sem sala.
%
% eventosSemSalasDiaSemana(DiaDaSemana, EventosSemSala): EventosSemSala 
% e' a lista de IDs dos eventos sem sala que ocorrem num DiaDaSemana.
% ---------------------------------------------------------------------

eventosSemSalas(EventosSemSala) :-
	findall(ID, evento(ID, _, _, _, semSala), EventosSemSala_aux),
	sort(EventosSemSala_aux, EventosSemSala).

eventosSemSalasDiaSemana(DiaDaSemana, EventosSemSala) :-
    findall(ID, (horario(ID, DiaDaSemana, _, _, _, _), 
    evento(ID, _, _, _, semSala)), EventosSemSala_aux),
    sort(EventosSemSala_aux, EventosSemSala).

%-------------------------------------------------------------------------
% eventosSemSalasPeriodo(ListaPeriodos, EventosSemSala): EventosSemSala
% e' uma lista de IDs dos eventos sem sala nos periodos de ListaPeriodos.
%
% aux_periodo(Per, Per_completo) : Per_completo e' uma lista de periodos
% que engloba os periodos semestrais para p1 simbolizar ambos p1 e p1_2
% por exemplo. Usada sempre que as disciplinas semestrais sao envolvidas.
% ------------------------------------------------------------------------

eventosSemSalasPeriodo([], []):- !.
eventosSemSalasPeriodo([Per|Resto], EventosSemSala) :-
    aux_periodo(Per, Per_completo),
    findall(ID, (horario(ID, _, _, _, _, Periodo), evento(ID, _, _, _, semSala),
    member(Periodo, Per_completo)), Eventosnoperiodo),
    eventosSemSalasPeriodo(Resto, EventosSemSalaAcumulador),
    append(Eventosnoperiodo, EventosSemSalaAcumulador, EventosSemSala_aux),
    sort(EventosSemSala_aux, EventosSemSala).

aux_periodo(Per, Per_completo) :-
    (Per = p1 -> Per_completo = [p1, p1_2]) ;
    (Per = p2 -> Per_completo = [p2, p1_2]) ;
    (Per = p3 -> Per_completo = [p3, p3_4]) ;
    (Per = p4 -> Per_completo = [p4, p3_4]).
    
%3.2

%---------------------------------------------------------------------
% organizaEventos(ListaEventos, Periodo, EventosNoPeriodo): 
% EventosNoPeriodo simboliza a lista de IDs de eventos da ListaEventos
% que ocorrem no periodo Periodo. 
% ---------------------------------------------------------------------

organizaEventos([], _, []):- !.
organizaEventos([Evento|Resto], Periodo, EventosNoPeriodo) :-
    aux_periodo(Periodo, Per_completo),
    (horario(Evento, _, _, _, _, Per), member(Per, Per_completo)),
    organizaEventos(Resto, Periodo, EventosNoPeriodoAcumulador),
    append([Evento], EventosNoPeriodoAcumulador, EventosNoPeriodoAux),
    sort(EventosNoPeriodoAux, EventosNoPeriodo).
organizaEventos([_|Resto], Periodo, EventosNoPeriodo) :-
    organizaEventos(Resto, Periodo, EventosNoPeriodo).

%---------------------------------------------------------------------
% eventosMenoresQue(Duracao, ListaEventosMenoresQue):
% ListaEventosMenoresQue e' a lista de IDs de eventos com duracao
% menor ou igual a Duracao.
%
% eventosMenoresQueBool(ID, Duracao): e' verdade se o evento com 
% identificacao ID tiver duracao menor ou igual a Duracao.
% ---------------------------------------------------------------------

eventosMenoresQue(Duracao, ListaEventosMenoresQue) :-
    findall(ID, (horario(ID, _, _, _, Dur_Ev, _), Dur_Ev @=< Duracao), Lista_aux),
    sort(Lista_aux, ListaEventosMenoresQue).

eventosMenoresQueBool(ID, Duracao) :-
    (horario(ID, _, _, _, Dur_Ev, _), Dur_Ev @=< Duracao).

%---------------------------------------------------------------------
% procuraDisciplinas(Curso, ListaDisciplinas): 
% ListaDisciplinas e' a lista das disciplinas por ordem
% alfabetica do curso Curso.
% ---------------------------------------------------------------------

procuraDisciplinas(Curso, ListaDisciplinas) :-
    findall(ID, turno(ID, Curso, _,_), ListaID),
    sort(ListaID, ListaID_sorted),
    findall(Disciplina, (evento(ID, Disciplina, _, _ , _), 
    member(ID, ListaID_sorted)), ListaDisciplinas_aux),
    sort(ListaDisciplinas_aux, ListaDisciplinas).

%---------------------------------------------------------------------
% organizaDisciplinas(ListaDisciplinas, Curso, Semestres): Semestres
% e' uma lista de duas listas, onde a primeira contem as disciplinas da
% ListaDisciplinas do curso Curso que pertencem ao primeiro semestre.
% Na segunda lista aplica se o mesmo para o segundo semestre.
% ---------------------------------------------------------------------

organizaDisciplinas(Disciplinas, Curso, Resultado) :-
    length(Disciplinas, TotalDisciplinas),
    organizaDisciplinas(Disciplinas, Curso, TotalDisciplinas, [[], []], Resultado).

organizaDisciplinas([], _, _, Semestres, Semestres).
organizaDisciplinas([Disciplina|Resto], Curso, TotalDisciplinas, [Semestre1, Semestre2], Resultado) :-
    evento(ID, Disciplina, _, _, _),
    turno(ID, Curso, _, _),
    horario(ID, _, _, _, _, Periodo),
    (   member(Periodo, [p1, p2, p1_2])
    ->  append(Semestre1, [Disciplina], NovoSemestre1),
        organizaDisciplinas(Resto, Curso, TotalDisciplinas, [NovoSemestre1, Semestre2], Resultado)
    ;   member(Periodo, [p3, p4, p3_4])
    ->  append(Semestre2, [Disciplina], NovoSemestre2),
        organizaDisciplinas(Resto, Curso, TotalDisciplinas, [Semestre1, NovoSemestre2], Resultado)
    ;   % Periodo diferente de p1, p2, p1_2, p3, p4, ou p3_4
        organizaDisciplinas(Resto, Curso, TotalDisciplinas, [Semestre1, Semestre2], Resultado)
    ).    

%-----------------------------------------------------------------------
% horasCurso(Periodo, Curso, Ano, TotalHoras): TotalHoras e' o numero
% de horas dos eventos associados ao curso Curso, no ano Ano e no 
% respetivo Periodo, usando o sum_list como predicado auxiliar.
%
% evolucaoHorasCurso(Curso, Evolucao): Evolucao e' uma lista de tuplos 
% na forma (Ano, Periodo, NumHoras), em que NumHoras e' o total de horas 
% do curso Curso, no ano Ano e periodo Periodo, usando o
% horasCurso como predicado auxiliar.
% ----------------------------------------------------------------------

horasCurso(Periodo, Curso, Ano, TotalHoras) :- 
    aux_periodo(Periodo, Per_completo),
    findall(ID, turno(ID, Curso, Ano, _), EventosAnoCurso_Aux),
    sort(EventosAnoCurso_Aux, EventosAnoCurso),
    findall(Duracao, (horario(ID, _, _, _, Duracao, Per), 
    member(ID, EventosAnoCurso), member(Per, Per_completo)),ListaDuracao ),
    sum_list(ListaDuracao, TotalHoras).

evolucaoHorasCurso(Curso, Evolucao) :-
    findall((Ano, Periodo, TotalHoras),
        (member(Ano, [1,2,3]), member(Periodo, [p1, p2, p3, p4]), 
        horasCurso(Periodo, Curso, Ano, TotalHoras)),
        Evolucao_Aux),
    sort(Evolucao_Aux, Evolucao).

%3.3 

%-----------------------------------------------------------------------------------
% ocupaSlot(HoraInicioDada, HoraFimDada, HoraInicioEvento, HoraFimEvento, Horas) :
% Horas e' o numero de horas sobrepostas entre o evento que tem inicio em 
% HoraInicioEvento e fim em HoraFimEvento, e o slot que tem inicio em HoraInicioDada 
% e fim em HoraFimDada. 
% ----------------------------------------------------------------------------------

ocupaSlot(HoraInicioDada, HoraFimDada, HoraInicioEvento, HoraFimEvento, Horas) :-
    %verificar os 4 casos dados no enunciado
    Horas is HoraFimEvento - HoraInicioEvento, HoraInicioEvento @>= HoraInicioDada,
    HoraFimEvento @=< HoraFimDada;
    Horas is HoraFimDada - HoraInicioDada, HoraInicioEvento @=< HoraInicioDada, 
    HoraFimEvento @>= HoraFimDada;
    Horas is HoraFimDada - HoraInicioEvento, HoraInicioEvento @>= HoraInicioDada, 
    HoraFimEvento @>= HoraFimDada, HoraInicioEvento @=< HoraFimDada;
    Horas is HoraFimEvento - HoraInicioDada, HoraInicioEvento @=< HoraInicioDada, 
    HoraFimEvento @=< HoraFimDada, HoraFimEvento @>= HoraInicioDada.

%----------------------------------------------------------------------------------------------
% numHorasOcupadas(Periodo, TipoSala, DiaSemana, HoraInicio, HoraFim, SomaHoras):
% SomaHoras e' o numero de horas ocupadas nas salas do tipo TipoSala, no
% intervalo de tempo entre HoraInicio e HoraFim, no dia da semana DiaSemana,
% e no periodo Periodo.
%
% ocupaslot_Aux(HoraInicioDada, HoraFimDada, ListaHoraInicio, ListaHoraFim , Acumulador, Horas):
% Este predicado funciona como o ocupaSlot, no entanto em vez de receber uma hora de inicio
% e uma de fim, recebe uma lista de horas iniciais e uma lista de horas finais, sendo Horas
% uma lista com as duracoes de todos os eventos dados a partir das 2 listas.
% Este predicado foi usado como auxiliar no numHorasOcupadas.
% ---------------------------------------------------------------------------------------------

numHorasOcupadas(Periodo, TipoSala, DiaSemana, HoraInicio, HoraFim, SomaHoras) :-
    salas(TipoSala, L_Sala),
    aux_periodo(Periodo, Per_completo),
    findall(ID, (evento(ID, _, _, _, Sala), member(Sala, L_Sala)), ListaID),
    findall(Hora_In,(horario(ID, DiaSemana, Hora_In, _, _, Per), 
    member(ID,ListaID), member(Per, Per_completo)), ListaInicio),
    findall(Hora_Fin,(horario(ID, DiaSemana, _, Hora_Fin, _, Per), 
    member(ID,ListaID), member(Per, Per_completo)), ListaFinal),
    ocupaslot_Aux(HoraInicio, HoraFim, ListaInicio, ListaFinal, [], Horas),
    sum_list(Horas, SomaHoras).

ocupaslot_Aux(_, _, [], [], Acumulador, Acumulador).
ocupaslot_Aux(HoraInicioDada, HoraFimDada, [HoraInicioEvento|Resto1], [HoraFimEvento|Resto2], Acumulador, Horas) :-
    ocupaSlot(HoraInicioDada, HoraFimDada, HoraInicioEvento, HoraFimEvento, Sobreposicao),
    append(Acumulador, [Sobreposicao], NovoAcumulador),
    ocupaslot_Aux(HoraInicioDada, HoraFimDada, Resto1, Resto2, NovoAcumulador, Horas).
ocupaslot_Aux(HoraInicioDada, HoraFimDada, [HoraInicioEvento|Resto1], [HoraFimEvento|Resto2], Acumulador, Horas) :-
    \+ ocupaSlot(HoraInicioDada, HoraFimDada, HoraInicioEvento, HoraFimEvento, _),
    ocupaslot_Aux(HoraInicioDada, HoraFimDada, Resto1, Resto2, Acumulador, Horas).

%----------------------------------------------------------------------------------------
% ocupacaoMax(TipoSala, HoraInicio, HoraFim, Max): Max e' o numero de horas 
% maximo possivel de ser ocupado em salas do tipo TipoSala, no intervalo 
% definido entre HoraInicio e HoraFim.
%
% percentagem(SomaHoras, Max, Percentagem): Percentagem e' a divisao de
% SomaHoras(numHorasOcupadas) por Max(ocupacaoMax), multiplicada por 100.
%
% ocupacaoCritica(HoraInicio, HoraFim, Threshold, Resultados):
% Resultados e' uma lista ordenada de tuplos do tipo casosCriticos(DiaSemana, TipoSala,
% Percentagem) em que DiaSemana e' um dia da semana, TipoSala e' um tipo de sala e 
% Percentagem e' a percentagem de ocupacao que tem de estar acima de um valor, o Threshold.
% ---------------------------------------------------------------------------------------

ocupacaoMax(TipoSala, HoraInicio, HoraFim, Max) :-
    salas(TipoSala, L_Sala), 
    length(L_Sala, Tam),
    Max is (HoraFim - HoraInicio) * Tam.

percentagem(SomaHoras, Max, Percentagem) :-
    Percentagem is (SomaHoras / Max) * 100.

ocupacaoCritica(HoraInicio, HoraFim, Threshold, Resultados) :-
    findall(SalaTipo, salas(SalaTipo, _), Lista_TipoSala),
    findall((casosCriticos(DiaSemana, TipoSala, Percent_Arredondada)),
        (member(DiaSemana, [segunda-feira, terca-feira, quarta-feira, quinta-feira, sexta-feira]), 
        member(TipoSala, Lista_TipoSala),
        member(Periodo, [p1, p2, p3, p4]),
        numHorasOcupadas(Periodo, TipoSala, DiaSemana, HoraInicio, HoraFim, SomaHoras),
        ocupacaoMax(TipoSala, HoraInicio, HoraFim, Max),
        percentagem(SomaHoras, Max, Percentagem),
        Percentagem > Threshold,
        ceiling(Percentagem, Percent_Arredondada)),
        Resultados_Aux),
    sort(Resultados_Aux, Resultados).


%3.4

