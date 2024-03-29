using System;
using System.Data;
using Microsoft.SqlServer.Server;
using System.Data.SqlTypes;
using System.Text.RegularExpressions;
using System.Text;

public static class AlphaNumericSort
{
  static readonly Regex integerRegex = new Regex(
      "[0-9]+",
      RegexOptions.Compiled
      | RegexOptions.ExplicitCapture);

  static readonly Regex integerAndHexRegex = new Regex(
      "((?<=0x)[0-9A-F]+)|([0-9]+)",
      RegexOptions.Compiled
      | RegexOptions.ExplicitCapture
      | RegexOptions.CultureInvariant
      | RegexOptions.IgnoreCase);

  private static void AppendLengthCode(StringBuilder sb, int len)
  {
    // I expect most integer sequences to be 9 or fewer digits.  This allows a single digit prefix to determine the
    // relative order of these sequences.
    const int largestSmallMagnitude = 9;
    if (len <= largestSmallMagnitude)
    {
      // Append the single digit prefix to give overall order for the integer segment.
      sb.Append("012345678"[(len - 1)]);
    }
    else
    {
      // The sequence is longer than 9 digits.  Code with the special 'this is a long sequence' code that orders these numbers after the shorter
      // numbers.
      sb.Append('9');

      // Get a 'length' code.  This is how long the digit sequence is.  Can subtract the largest small magnitude to normalize it to 0 for the smallest 'large' magnitude.
      string lenText = (len - largestSmallMagnitude - 1).ToString();

      // double code the length.
      // This allows coding up to 10^9, without consuming too much extra space (log(n) space)
      sb.Append(lenText.Length.ToString());
      sb.Append(lenText);
    }
  }

  /// <summary>
  /// Get a string token that will sort correctly given mixed numeric (integer) and text strings.
  /// </summary>
  /// <param name="s">The string to convert to an alpha-numeric order token</param>
  /// <returns>A token that when ordered, will give ascending order for text intepreted with integer components.</returns>
  public static string GetAlphaNumericOrderToken(string s)
  {
    return GetAlphaNumericOrderTokenI(s, false);
  }

  /// <summary>
  /// Get a string token that will sort correctly given mixed numeric (integer) and text strings.
  /// </summary>
  /// <param name="s">The string to convert to an alpha-numeric order token</param>
  /// <param name="ignoreZeroPadding">Indication whether to ignore left zero padding when generating token for lexical ordering of numeric values.</param>
  /// <returns>A token that when ordered, will give ascending order for text intepreted with integer components.</returns>
  private static string GetAlphaNumericOrderTokenI(string s, bool includeHexPatterns)
  {
    return GetAlphaNumericOrderTokenI(s, includeHexPatterns, true);
  }

  /// <summary>
  /// Get a string token that will sort correctly given mixed numeric (integer) and text strings.
  /// </summary>
  /// <param name="s">The string to convert to an alpha-numeric order token</param>
  /// <param name="ignoreZeroPadding">Indication whether to ignore left zero padding when generating token for lexical ordering of numeric values.</param>
  /// <returns>A token that when ordered, will give ascending order for text intepreted with integer components.</returns>
  private static string GetAlphaNumericOrderTokenI(string s, bool includeHexPatterns, bool ignoreZeroPadding)
  {
    // Special case for null.
    if (s == null)
    {
      return s;
    }

    // Any sequence of digits [0-9] needs to be coded to ensure it is ordered correctly.
    MatchCollection matches;
    if (includeHexPatterns)
    {
      // Use the combination hex/integer patterns.
      matches = integerAndHexRegex.Matches(s);
    }
    else
    {
      // Use the integer only hex/integer patterns.
      matches = integerRegex.Matches(s);
    }
    if (matches.Count == 0)
    {
      // No embedded integer text.  No transform is needed.
      return s;
    }

    // Create a string builder.  The size estimate assumes most numbers will be fewer than 9 digits.
    StringBuilder sb = new StringBuilder(s.Length + matches.Count * 2);

    // Create a string builder to append terminal zero padding determinations; assume 1 per match.
    StringBuilder zeroPadOrder = null;
    if (ignoreZeroPadding)
      zeroPadOrder = new StringBuilder(matches.Count);

    int pos = 0;
    foreach (Match match in matches)
    {
      // Add text preceding the integer text.
      sb.Append(s, pos, match.Index - pos);

      // Encode the length of integer text, skipping any initial zeros.
      int len = match.Length;

      // Don't count any '0' prefix characters in the length.
      int zeros = 0;
      if (ignoreZeroPadding)
      {
        while (zeros + 1 < len && s[match.Index + zeros] == '0')
        {
          ++zeros;
        }
        len -= zeros;
      }

      // Append length code, the number (without zeros), and the zero length code.
      AppendLengthCode(sb, len);
      sb.Append(s, match.Index + zeros, match.Length - zeros);
      if (ignoreZeroPadding)
      {
        AppendLengthCode(zeroPadOrder, zeros + 1);
      }

      // Set the position for non-numeric text.
      pos = match.Index + match.Length;
    }

    // Add any remaining text.
    sb.Append(s, pos, s.Length - pos);

    // Add zero pad order.
    if (ignoreZeroPadding)
    {
      sb.Append(" ");
      sb.Append(zeroPadOrder);
    }

    // Return the token for ordering the string.
    return sb.ToString();
  }
}