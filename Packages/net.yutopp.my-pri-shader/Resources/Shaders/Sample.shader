Shader "Example/URPUnlitShaderBasic"
{
    // Unityから受け取るパラメータを指定する場所。この例では空
    Properties
    { }

    // Shader本体を記述する場所
    SubShader
    {
        // このSubShaderのレンダリングパイプラインにURPを利用するという指定
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            // HLSLコードブロックの開始
            HLSLPROGRAM

            // 頂点シェーダの名前を 'vert' と定義
            #pragma vertex vert
            // フラグメントシェーダの名前を 'frag' と定義
            #pragma fragment frag

            // URPパッケージに含まれる便利マクロや関数などを読み込む
            // このパッケージのディレクトリ以下には他にも様々なライブラリが提供されている。
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // この例では 'Attributes' 構造体を頂点シェーダの入力として使う
            struct Attributes
            {
                // 'positionOS' 変数はオブジェクト空間の頂点座標を持つ
                float4 positionOS   : POSITION;
            };

            struct Varyings
            {
                // SV_POSITION という意味の、クリップ空間の頂点座標をこの構造体では持っている必要がある
                float4 positionHCS  : SV_POSITION;
            };

            // 上記の 'Varyings' 構造体で定義されたプロパティと頂点シェーダの定義
            // この vert 関数の返す型は、上記の構造体と同じである必要がある
            Varyings vert(Attributes IN)
            {
                // Varyings構造体で出力データの (OUT)を宣言
                Varyings OUT;
                // TransformObjectToHClip関数で、頂点座標をオブジェクト空間からクリップ空間に変換
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                // 出力を返す
                return OUT;
            }

            // フラグメントシェーダの定義
            half4 frag() : SV_Target
            {
                // 色を固定で定義したものを結果として返す
                half4 customColor = half4(0.5, 0, 0, 1);
                return customColor;
            }

            ENDHLSL
        }
    }
}
