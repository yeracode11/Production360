import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/document_author_support.dart';
import '../../core/theme/app_colors.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';

/// Строка «Автор» на экранах деталей документа.
class DocumentAuthorRow extends StatelessWidget {
  const DocumentAuthorRow({
    super.key,
    this.login,
    this.highlightCurrentUser = false,
  });

  final String? login;
  final bool highlightCurrentUser;

  @override
  Widget build(BuildContext context) {
    final value = login?.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              AppStrings.author,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.deepBrownLight,
                  ),
            ),
          ),
          Expanded(
            child: value != null && value.isNotEmpty
                ? Row(
                    children: [
                      Expanded(child: _AuthorIdentity(login: value)),
                      if (highlightCurrentUser) ...[
                        const SizedBox(width: 8),
                        _YouBadge(),
                      ],
                    ],
                  )
                : Text(
                    '—',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Read-only поле «Автор» в форме создания документа.
class DocumentAuthorField extends StatelessWidget {
  const DocumentAuthorField({
    super.key,
    required this.login,
    this.highlightCurrentUser = false,
  });

  final String login;
  final bool highlightCurrentUser;

  @override
  Widget build(BuildContext context) {
    final value = login.trim();
    if (value.isEmpty) {
      return const SizedBox.shrink();
    }

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: AppStrings.author,
      ),
      child: Row(
        children: [
          Expanded(child: _AuthorIdentity(login: value)),
          if (highlightCurrentUser) ...[
            const SizedBox(width: 8),
            _YouBadge(),
          ],
        ],
      ),
    );
  }
}

/// Автор документа: из API, локального кэша или текущий пользователь.
class ResolvedDocumentAuthorRow extends StatelessWidget {
  const ResolvedDocumentAuthorRow({
    super.key,
    required this.documentId,
    this.authorLogin,
    this.author,
  });

  final String documentId;
  final String? authorLogin;
  final String? author;

  @override
  Widget build(BuildContext context) {
    final resolved = DocumentAuthorSupport.resolveLogin(
      documentId: documentId,
      authorLogin: authorLogin,
      author: author,
    );

    if (resolved != null && resolved.isNotEmpty) {
      return DocumentAuthorRow(login: resolved);
    }

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return DocumentAuthorRow(
            login: state.user.username,
            highlightCurrentUser: true,
          );
        }
        return const DocumentAuthorRow();
      },
    );
  }
}

/// Автор при создании документа — текущий пользователь.
class CurrentUserAuthorRow extends StatelessWidget {
  const CurrentUserAuthorRow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) return const SizedBox.shrink();
        return DocumentAuthorField(
          login: state.user.username,
          highlightCurrentUser: true,
        );
      },
    );
  }
}

/// Строка автора для read-only превью (заказ и т.п.).
class DocumentAuthorPreviewLine extends StatelessWidget {
  const DocumentAuthorPreviewLine({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return DocumentAuthorRow(
            login: state.user.username,
            highlightCurrentUser: true,
          );
        }
        return const DocumentAuthorRow();
      },
    );
  }
}

class _AuthorIdentity extends StatelessWidget {
  const _AuthorIdentity({required this.login});

  final String login;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _AuthorAvatar(login: login),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            login,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({required this.login});

  final String login;

  @override
  Widget build(BuildContext context) {
    final initial =
        login.trim().isNotEmpty ? login.trim()[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.mintSoft,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.turquoiseDark,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _YouBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.mintSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.turquoise.withValues(alpha: 0.35)),
      ),
      child: Text(
        AppStrings.authorCurrentUserBadge,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.turquoiseDark,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
