## ICHSD - Clean up the Hardsub Sources for Decimation<br><font size=3>Created by Ikotas</font>

([English and other languages](https://ikotas-github-io.translate.goog/ICHSD/?_x_tr_sl=ja&_x_tr_tl=en&_x_tr_hl=en)) <span style="font-size:80%;">by Google Translate</span>

#### はじめに：
<div style="padding-left:20px;">

埋め込み字幕(Hardsub)を含むインターレースソースをDecimationするために、問題点(後述)を解消して整えるスクリプトです。<br>
対応するインターレースソースは、23.976fpsを29.97fpsへテレシネした、PIIPP (プログレッシブ3枚、インターレース2枚の繰り返し、TFMでのフィールドマッチング後のMatch Codesの並びは cppcc )のパターンのみです。<br>
サンプル試行数は少ないですが、上手く動作しているように見えます。<br>
どなたかのお役に立てば幸いです。<br>
<br>
※たまに出てくる英語部分は、自動翻訳を意識しています。  
</div>


#### 実装機能：  

<b>

1. Decimationで確実に間引かれるための、重複フレームの片方を複製し、もう片方を上書きして置き換える処理  

2. 片フィールド字幕の除去(*1) (処理方法を選択可)  

3. パターンマッチによるMatch Code(*2)判定  

4. 縞(Combs)部分の自動除去処理(*1) (処理方法を選択可)  

5. 自動処理後に更に残留する縞(Combs)を手動で処理する手段の提供  
</b>

<div style="padding-left:20px;">

*1…除去処理自体はCombReduceまたはインターレース解除で実施<br>
*2…TFM(TIVTC)の用語、本プラグインでは以下を使用(`mode=2`)
</div>

<div style="padding-left:60px;">

p = match to previous field<br>
c = match to current field<br>
u = match to next field
</div>


#### Syntax and Parameters：
<div style="padding-left:20px;">

    ICHSD(clip input, int "cr", float "ythresh", int "mthresh", bool "manual",
        int "cr1f", int "cr1t", int "cr2f", int "cr2t", int "cr3f", int "cr3t",
        int "cr4f", int "cr4t", int "cr5f", int "cr5t", bool "show", int "ml",
        bool "ulp", int "suby")
</div>
<div style="padding-left:20px;">

    cr       片フィールド字幕と残留縞(Combs)の処理方法を選択。
             deint(インターレース解除)はTFM(pp=3)で実行。
             ※CombReduceのmode=1,2で使用するプラグインが異なりますが、具体的な処理の違いは不明です。

                 0 - deint
                 1 - CombReduce(mode=1)
                 2 - CombReduce(mode=2)

             defalut：1 (int)


    ythresh  シーンチェンジを判定するYDifferenceFromPreviousの閾値を設定。
             超えた場合はインターレース解除の判定に進む。

             defalut：20.0 (float)


    mthresh  ythreshのあとにインターレース解除を判定するTFMMicの閾値を設定。
             本閾値の処理は、シーンチェンジであると判定されたあとにのみ実行するため、非常に限定的。

             0<=n<=4096 ※blockx=64,blocky=64の場合

             defalut：2000 (int)


    manual   残留縞(Combs)の手動処理の実行有無を設定。
             次のパラメーターで対象範囲を設定する。

             defalut：false (bool)


    cr(n)f   縞(Combs)がある範囲の開始フレーム番号と終了フレーム番号を設定。
    - cr(n)t 設定した範囲内のみインターレース解除を行う。
     n=1-5   最大5パターンの範囲を設定可能。
             cr1f-cr1t, cr2f-cr2t, cr3f-cr3t, cr4f-cr4t, cr5f-cr5t
             0の場合は無視するため、フレーム0では実行不可。
             ※フレーム0はIsCombedTIVTCの判定により自動でインターレース解除します。

             defalut：0 (int)


    show     現在表示しているフレームに関連情報を出力。

             defalut：false (bool)


    ml       フレーム関連情報内のMATCH Codesリストの表示数を指定。

             defalut：21 (int)


    ulp      動きの少ない箇所のパターンマッチ処理の実行有無を設定。
             falseにすると、cpppc と並んだ3番目の p を c に変換する処理もキャンセルする。

             defalut：true (bool)


    saby     フレーム関連情報の縦方向の出力位置を指定。
             他のプラグイン等の情報を同時に出力する場合に重ならずに表示できる。
             ※本スクリプト内のTFMやConfditionalFilter等の情報出力を有効にすると、
               正しく判定処理が行われなくなるためご注意ください。

             defalut：0 (int)

</div>


#### 説明：

1. **埋め込み字幕(Hardsub)ありのインターレースソースに特化**

    Hardsubの始点・終点が重複フレームに掛かった箇所は、Decimationの際に、片方のフレームに残る片フィールド字幕のために重複フレームではないと判定され、代わりにその他の必要なフレームが取り除かれてしまいます。  
この問題点を解消するために、次の処理を行います。

    (1) TFMでフィールドマッチング後のMatch Codes cppccを12345とした場合、1,2が重複フレームのため、1を複製して2に置き換える。

      　　12345(cppcc) -> 11345(ccpcc)

    また、Decimationには影響しませんが、視聴時に気になるため、もう一方の p に掛かった片フィールド字幕も処理します。

    (2) (1)のあとに3をCombReduceで処理する。

      　　11345(ccpcc) -> 113'45(ccp'cc)

2. **TFMのフィールドマッチングと、Frame Propaties(TFMMatch,TFMMics)を使用**

    TFMMatchでMatch Codesを処理判定に使えることが分かり、アイデアが膨らんだことが、作成し始めたきっかけです。  
    当初は、シンプルに判定して処理できると思ったのですが、周期変化や29.97fps部分を考慮すると単純なルールに当てはめて変換することができず、結局結構なボリュームになってしまいました。(更に思いついた機能を盛り込んだため、動作も重めになってしまいました…。)  
    PropSetを活用するアイデアもありましたが、残念ながら処理速度に影響したため、今回は使用していません。(私の環境ではAvsPmod上で10fps程度低下しました。)

    TFMの設定は、以下を前提とします。

    `TFM(mode=2,pp=1,slow=2,micmatching=2,mmsco=false,metric=1,blockx=64,blocky=64)`

    <u>mode=2,micmatching=2,mmsco=false,metric=1</u>  
    mode=0のみでは片フィールド字幕のフレームが c と判定される場合が多く、どうしても機械的に処理できないケースが発生します。  
本設定で u を有効にすると、当該フレームが u と判定されるため、機械的に処理できるようになります。  
(このことに気づくことができなければ、行き詰ったままお蔵入りになるところでした…。)

    <u>blockx=64,blocky=64</u>  
    こちらは根拠はありませんが、成り行きでこの値にしています。  
変更する場合は、合わせてmthreshの値も変更してください。

3. **閾値をなるべく使用しない判定**

    フレーム内に縞(Combs)がどれだけ含まれるかといった基準で判定しようとすると、どうしても例外が出てきたり、ソース毎に調整し直さなければならなかったりします。  
    閾値をなるべく使用せずに済む判定基準を使用することで、閾値の使用を2個(`ythresh`,`mthresh`)までに抑えています。  

* 使用する判定基準  

<div style="padding-left:20px;">

1. パターンマッチ  
   事項で説明

2. `LumaDifference(base,base.Loop(n+1,0,-1).Trim(0,FrameCount()-1))<ythresh`  
3. `LumaDifference(base,base.Trim(n,0).Loop(n+1,FrameCount()-1,-1))<ythresh`  
   現在表示しているフレームと、n個前方(2.)または後方(3.)のフレームを比較し、シーンチェンジがないかを確認。  
   パターンマッチで使用します。  
   シーンチェンジがなければパターンに適合、あれば不適合としています。

4. `YDifferenceFromPrevious()>ythresh`  
   一つ手前のフレームと比較し、シーンチェンジがないかを確認。  
   シーンチェンジがあれば、5.に進み、なければ6.に進みます。  

5. `propGetInt(ovr(p/c),"TFMMics",index=(0/1))>mthresh`  
   現在のフレームのMic値(*)を取得し、インターレース解除を行うかを確認。  
   閾値超はインターレース解除、閾値以下は6.に進みます。  

6. `LumaDifference(ovr(p/c),ovr(p/c).CombReduce())`  
   TFMのovr(overrides)機能で、全フレームを強制的に c または p に上書きしたソースを、それぞれCombReduceを適用した状態と比較し、縞(Combs)が含まれるかを確認。  
ovrcとovrpのどちらにも差分が存在した場合は、`cr`の設定に従い、CombReduce適用かインターレース解除を行います。  

</div>

<div style="padding-left:40px;">

*Mic値…TFM用語、指定した大きさ(本スクリプトでは`blockx=64,blocky=64`)の枠内にどれだけ縞(Combs)が含まれるかを表した指標、何の略？

<u>[ovrc.txt](https://github.com/Ikotas/ICHSD/raw/main/ovrc.txt)</u>、<u>[ovrp.txt](https://github.com/Ikotas/ICHSD/raw/main/ovrp.txt)</u>  
    TFMのovr用ファイル  

</div>

4. **パターンマッチによる判定**

   本スクリプトが対象とするインターレースソースの5フレーム毎のMatch Codesの配置は、原則以下のパターンの何れかです。  

</div>
<div style="padding-left:80px;">

ppccc  
cppcc  
ccppc  
cccpp  
pcccp  

</div>
<div style="padding-left:28px;">

しかし、実際には、カット編集・CM分断による周期変化や29.97fpsのシーンやTFMのフィールドマッチング処理等の要因により、様々な配置パターンとなります。  
単純にはMatch Codeの特定はできないため、複数のパターンマッチを用いて、精度を高めています。

</div>

* 使用するパターンマッチ

<div style="padding-left:20px;">

1. 現在のフレームの前後2個ずつMatch Codeを確認  
   前後のフレームのMatch Codeを確認し、上記の原則の配置に当てはめることで、現在のフレームのMatch Codeを推測します。  
   p と推測される場合は、基本的に2.に進みます。  
   c と推測される場合は、隣接するフレームが p の場合は基本的に2.に進み、隣接するフレームがどちらも c の場合は3.に進みます。  

</div>
<div style="padding-left:20px;">

2. 現在のフレームの前後最大31フレーム先まで pp の並びを確認  
   前方後方のppの配置をパターンと照合して、現在のフレームのMatch Codeを決定します。  
   誤判定を抑制するために、20フレーム以上離れている場合と、片方向のみ適合する場合は、シーンチェンジがないことも合わせて確認します。  

3. パターンリストを使用して、現在のフレームを中心とした前後合わせて22フレーム分のMatch Codeの配置を確認  
   外部ファイルのパターンリストを使用して、TFMが判定できずに c が並ぶ範囲でも、パターンに適合した場合は c を p に変換します。  
   片フィールド字幕のフレームが埋もれている場合に掘り起こして適切に処理できる場合があります。  
   ただし、本編以外の29.97fpsのシーンやアニメ等の静止画が続くソースで、たまたまパターンにマッチして余計な変換が発生する可能性もあります。  
   ※オプションでOFFに設定可能(`ulp=false`)

</div>

<div style="padding-left:40px;">

<u>[ICHSD_patternlist.txt](https://github.com/Ikotas/ICHSD/raw/main/ICHSD_patternlist.txt)</u>  
c/p の並びを記載したパターンリスト

</div>

5. **インターレース解除は必要最小限のみ**

    インターレース解除よりフィールドマッチングの方が品質が良いと思っていますので、インターレース解除は必要な場合のみに限定しています。  
    インターレース解除に使用するプラグインは、TFM(pp=3)を使用していますが、お好みのプラグインに変更して問題ありません。  
    変更する場合は、deint, deintc, deintpの3つを同一の設定にすれば良いです。  
    ※deintc/deintpで c/p を強制している部分は、Match Codesリストの記号表示を見ることで、意図した通りの処理が行われていることを確認するための、デバッグ目的のために行っており、それがなくても他に影響は全くありません。

6. **縞(Combs)を自動と手動で処理可能**

    基本的にMic値に頼らずに処理するため、テロップ(telop)やスーパー(Superimpose)はそのまま残ります。
    動作確認中にテロップに気づいてしまい、このスクリプト外で処理して貰えば良いのでは？とも思いましたが、実装アイデアも閃いてしまったので取り組んだ結果、テロップ(telop)やスーパー(Superimpose)含めて、残った縞(Combs)を自動で処理するようにできました。  
    CombReduceとovrcまたはovrpを組み合わせた差分情報(LumaDifference)で検出して、CombReduceで処理します。※3.6.で説明  
    基本的にはCombReduceの自動処理のみで問題ないと思いますが、CombReduceは薄い色は対処しない方針のようで、薄い色のテロップの箇所や、片フィールド字幕よりも細かい縞(Combs)は、検出されずに残ります。  
    CombReduceが消しきれなかった縞(Combs)だけを機械的に正しく判定する方法が見つからないため、(やむを得ず)手動でインターレース解除できるようにしました。  
    当初テロップ(telop)の表示範囲を手動で設定するために用意したパラメーターで、縞(Combs)のある表示範囲を設定します。  
    表示範囲をフレーム番号で指定するため、残った縞(Combs)を探して特定する必要があります。  
    どうしても気になった箇所に、手動で設定して貰えればと思います。(`manual=true`)  
    表示範囲は5パターン設定可能です。  


#### 補足：

1. 1920x1080の実写ソースで調整・確認しましたので、その他の解像度やアニメ等では閾値の変更が必要になるかもしれません。

2. CombReduceは、ソースによっては片フィールド字幕を消しきれずに残像が発生することがあります。  
この場合は、mode=2(`cr=2`)にすることで解消するかもしれません。  
解消できずに残像が気になる場合は、インターレース解除に切り替え可能です。(`cr=0`)

#### 本スクリプト：
- [ICHSD.avsi](https://github.com/Ikotas/ICHSD/raw/main/ICHSD.avsi)


#### 必須バージョン、プラグイン、スクリプト：

- [AviSynth v3.7.1以降](https://github.com/pinterf/AviSynthPlus)
- [TIVTC.dll v1.0.27test以降](https://github.com/pinterf/TIVTC/)
- [CombReduce.avsi](https://quintrokk.subness.net/?p=1118) …片フィールド字幕を消去  
  ※コメント欄にスクリプトのリンクあり
  - nnedi3.dll
  - CombMask.dll
  - masktools2.dll
  - TDeint.dll
  - TMM2.dll  
<p style="padding-left:34px;">
本プラグインでは縞(Combs)の有無の判定にも使用
</p>


#### 必須ファイル：

- [ovrc.txt](https://github.com/Ikotas/ICHSD/raw/main/ovrc.txt)  
  内容  
  ```0,0 c```

- [ovrp.txt](https://github.com/Ikotas/ICHSD/raw/main/ovrp.txt)  
  内容  
  ```0,0 p```

- [ICHSD_patternlist.txt](https://github.com/Ikotas/ICHSD/raw/main/ICHSD_patternlist.txt)

<div style="padding-left:20px;">
※<b>初めにスクリプト内のファイルパスを環境に合わせて書き換える必要があります。</b>
</div>


#### Decimationを実行するプラグイン：
<div style="padding-left:20px;">
※本スクリプトには含まれません。<br>
<br>
特に指定はありませんが、現環境ですと選択肢は少ないため、実質TDecimate一択かと思います。<br>
<br>
本プラグインでTDecimateを使用する場合のおすすめ設定

    TDecimate(mode=0,cycleR=1,cycle=5,hint=false)

※`hint=false`は、まれに一致度の値を無視して、本スクリプトが複製したフレームではなく、TFMが判定したフレームを選んでしまう動作を抑制するために指定します。

</div>

#### その他おすすめスクリプト：
<div style="padding-left:20px;">
※本スクリプトには含まれません。<br><br>
</div>

- DecombUCF.avsi …IVTC後の汚いフレームをキレイなフレームに置換  
  ・[オリジナル](http://tyottoenc.blog.fc2.com/blog-entry-9.html)  ・[改良版](https://pastebin.com/GNX0UCrh)  
  - Zs_RF_Shared.avsi
  - SmoothAdjust.dll
  - TDeint.dll
  - TMM2.dll
  - variableblur.dll
  - warpsharp.dll  

<div style="padding-left:20px;">
  ※現在のAviSynthではConditionalFilterの箇所が要因で動作しないため修正が必要(改良版含む)<br>
　修正情報自体は転載禁止のため、使用する場合はご自分で探して適用してください。<br>
<br>

* 修正情報…Avisynthを絶讃ιょぅょ Part32 [無断転載禁止]©2ch.net No.548,571,604
</div>


#### おまけ：

* [Amatsukazeユーザーのための情報](https://github.com/Ikotas/ICHSD/raw/main/HowtorunICHSDonAmatsukaze.txt)


#### 他の作品

- 25fpsIVTCGuide  
  完全手作業の29.97fps→25fps逆テレシネ(IVTC)ガイド  
・[日本語](https://github.com/Ikotas/25fpsIVTCGuide)  ・[English and other languages](https://ikotas-github-io.translate.goog/25fpsIVTCGuide/?_x_tr_sl=ja&_x_tr_tl=en&_x_tr_hl=en) <span style="font-size:80%;">by Google Translate</span><br>


#### 更新履歴：

    2025.3.21 v1.0 初回リリース
